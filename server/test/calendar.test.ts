import { beforeEach, describe, expect, it, vi } from 'vitest';

const mockPrisma = {
  $queryRaw: vi.fn().mockResolvedValue(1),
  userSession: {
    findUnique: vi.fn().mockResolvedValue({
      userId: 'user-123',
      revokedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
      user: { suspendedAt: null },
    }),
  },
};

vi.mock('../src/lib/prisma.js', () => ({ prisma: mockPrisma }));

describe('calendar event endpoint', async () => {
  const { buildApp } = await import('../src/app.js');
  const { clearGoogleAccessTokenCacheForTests } = await import('../src/integrations/google/oauth.js');
  const app = buildApp();
  await app.ready();
  const token = app.jwt.sign({ userId: 'user-123', sessionId: 'sess-1', role: 'USER' });

  const validPayload = {
    title: 'Passport expiry',
    description: 'DueNest expiry reminder.',
    start: '2026-10-15T00:00:00',
    end: '2026-10-16T00:00:00',
    timeZone: 'Africa/Cairo',
  };

  beforeEach(() => {
    vi.restoreAllMocks();
    clearGoogleAccessTokenCacheForTests();
    mockPrisma.userSession.findUnique.mockResolvedValue({
      userId: 'user-123',
      revokedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
      user: { suspendedAt: null },
    });
  });

  it('rejects unauthenticated requests', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/calendar/events',
      payload: validPayload,
    });

    expect(response.statusCode).toBe(401);
  });

  it('rejects invalid date ranges before contacting Google', async () => {
    const googleFetch = vi.spyOn(globalThis, 'fetch');
    const response = await app.inject({
      method: 'POST',
      url: '/api/calendar/events',
      headers: { authorization: `Bearer ${token}` },
      payload: { ...validPayload, end: validPayload.start },
    });

    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe('INVALID_DATE_RANGE');
    expect(googleFetch).not.toHaveBeenCalled();
  });

  it('creates an authenticated event on the selected Cairo expiry date', async () => {
    const googleFetch = vi.spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(new Response(JSON.stringify({ access_token: 'test-access-token', expires_in: 3600 }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({
        id: 'event-123',
        htmlLink: 'https://calendar.google.com/calendar/event?eid=test',
      }), { status: 200 }));

    const response = await app.inject({
      method: 'POST',
      url: '/api/calendar/events',
      headers: { authorization: `Bearer ${token}` },
      payload: validPayload,
    });

    expect(response.statusCode).toBe(201);
    expect(response.json()).toEqual({
      eventId: 'event-123',
      eventLink: 'https://calendar.google.com/calendar/event?eid=test',
      created: true,
    });
    expect(mockPrisma.userSession.findUnique).toHaveBeenCalledOnce();

    const calendarRequest = googleFetch.mock.calls[1];
    const calendarBody = JSON.parse(calendarRequest?.[1]?.body as string);
    expect(calendarBody.start).toEqual({
      dateTime: '2026-10-14T21:00:00.000Z',
      timeZone: 'Africa/Cairo',
    });
    expect(calendarBody.end).toEqual({
      dateTime: '2026-10-15T21:00:00.000Z',
      timeZone: 'Africa/Cairo',
    });
    expect(calendarBody).not.toHaveProperty('accessToken');
  });

  it('returns a clear error when Calendar authorization is missing', async () => {
    vi.spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(new Response(JSON.stringify({ access_token: 'test-access-token' }), { status: 200 }))
      .mockResolvedValueOnce(new Response('{}', { status: 403 }));

    const response = await app.inject({
      method: 'POST',
      url: '/api/calendar/events',
      headers: { authorization: `Bearer ${token}` },
      payload: validPayload,
    });

    expect(response.statusCode).toBe(503);
    expect(response.json()).toEqual({
      error: 'CALENDAR_AUTHORIZATION_REQUIRED',
      message: 'Google Calendar authorization is missing. Please reconnect the application owner account.',
    });
  });

  it('returns a safe error when the Google Calendar API fails', async () => {
    vi.spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(new Response(JSON.stringify({ access_token: 'test-access-token' }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ error: { message: 'private upstream detail' } }), { status: 500 }));

    const response = await app.inject({
      method: 'POST',
      url: '/api/calendar/events',
      headers: { authorization: `Bearer ${token}` },
      payload: validPayload,
    });

    expect(response.statusCode).toBe(502);
    expect(response.body).not.toContain('private upstream detail');
    expect(response.json().error).toBe('CALENDAR_SERVICE_UNAVAILABLE');
  });

  it('returns the existing event after a duplicate insert', async () => {
    vi.spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(new Response(JSON.stringify({ access_token: 'test-access-token' }), { status: 200 }))
      .mockResolvedValueOnce(new Response('{}', { status: 409 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({
        id: 'event-existing',
        htmlLink: 'https://calendar.google.com/calendar/event?eid=existing',
      }), { status: 200 }));

    const response = await app.inject({
      method: 'POST',
      url: '/api/calendar/events',
      headers: { authorization: `Bearer ${token}` },
      payload: validPayload,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().created).toBe(false);
    expect(response.json().eventId).toBe('event-existing');
  });
});
