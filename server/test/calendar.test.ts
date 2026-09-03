import { beforeEach, describe, expect, it, vi } from 'vitest';

const mockPrisma = {
  $queryRaw: vi.fn().mockResolvedValue(1),
  $transaction: vi.fn(async (operations: Promise<unknown>[]) => Promise.all(operations)),
  userSession: {
    findUnique: vi.fn().mockResolvedValue({
      userId: 'user-123',
      revokedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
      user: { suspendedAt: null },
    }),
  },
  googleCalendarConnection: {
    findUnique: vi.fn(),
    upsert: vi.fn().mockResolvedValue({ id: 'connection-1' }),
    delete: vi.fn().mockResolvedValue({ id: 'connection-1' }),
  },
  googleCalendarOAuthAttempt: {
    findUnique: vi.fn(),
    create: vi.fn().mockResolvedValue({ id: 'attempt-1' }),
    delete: vi.fn().mockResolvedValue({ id: 'attempt-1' }),
    deleteMany: vi.fn().mockResolvedValue({ count: 0 }),
  },
};

vi.mock('../src/lib/prisma.js', () => ({ prisma: mockPrisma }));

describe('per-user calendar endpoint', async () => {
  const { buildApp } = await import('../src/app.js');
  const { clearGoogleAccessTokenCacheForTests } = await import('../src/integrations/google/oauth.js');
  const { encryptGoogleCalendarSecret } = await import('../src/integrations/google/calendar_connection.js');
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
    mockPrisma.$transaction.mockImplementation(async (operations: Promise<unknown>[]) => Promise.all(operations));
    mockPrisma.userSession.findUnique.mockResolvedValue({
      userId: 'user-123',
      revokedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
      user: { suspendedAt: null },
    });
    mockPrisma.googleCalendarConnection.findUnique.mockResolvedValue({
      id: 'connection-1',
      encryptedRefreshToken: encryptGoogleCalendarSecret('test-user-calendar-refresh-token'),
      createdAt: new Date('2026-01-01T00:00:00Z'),
      updatedAt: new Date('2026-01-01T00:00:00Z'),
    });
  });

  it('rejects unauthenticated requests', async () => {
    const response = await app.inject({ method: 'POST', url: '/api/calendar/events', payload: validPayload });
    expect(response.statusCode).toBe(401);
  });

  it('returns the user connection status without returning any token', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/calendar/connection',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({ connected: true });
    expect(response.body).not.toContain('refresh-token');
  });

  it('starts a user-specific OAuth connection with a PKCE challenge', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/calendar/connection/authorize',
      headers: { authorization: `Bearer ${token}`, origin: 'http://localhost:3001' },
    });
    expect(response.statusCode).toBe(200);
    const url = new URL(response.json().authorizationUrl);
    expect(url.origin).toBe('https://accounts.google.com');
    expect(url.searchParams.get('scope')).toBe('https://www.googleapis.com/auth/calendar.events');
    expect(url.searchParams.get('code_challenge_method')).toBe('S256');
    expect(mockPrisma.googleCalendarOAuthAttempt.create).toHaveBeenCalledOnce();
    expect(response.body).not.toContain('code_verifier');
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

  it('requires the authenticated user to connect their own Calendar', async () => {
    mockPrisma.googleCalendarConnection.findUnique.mockResolvedValueOnce(null);
    const response = await app.inject({
      method: 'POST',
      url: '/api/calendar/events',
      headers: { authorization: `Bearer ${token}` },
      payload: validPayload,
    });
    expect(response.statusCode).toBe(409);
    expect(response.json().error).toBe('CALENDAR_CONNECTION_REQUIRED');
  });

  it('creates an event in the signed-in user’s primary Calendar on the selected Cairo date', async () => {
    const googleFetch = vi.spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(new Response(JSON.stringify({ access_token: 'test-access-token', expires_in: 3600 }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ id: 'event-123', htmlLink: 'https://calendar.google.com/calendar/event?eid=test' }), { status: 200 }));

    const response = await app.inject({
      method: 'POST',
      url: '/api/calendar/events',
      headers: { authorization: `Bearer ${token}` },
      payload: validPayload,
    });
    expect(response.statusCode).toBe(201);
    expect(response.json()).toEqual({ eventId: 'event-123', eventLink: 'https://calendar.google.com/calendar/event?eid=test', created: true });
    const calendarBody = JSON.parse(googleFetch.mock.calls[1]?.[1]?.body as string);
    expect(calendarBody.start).toEqual({ dateTime: '2026-10-14T21:00:00.000Z', timeZone: 'Africa/Cairo' });
    expect(calendarBody.end).toEqual({ dateTime: '2026-10-15T21:00:00.000Z', timeZone: 'Africa/Cairo' });
    expect(calendarBody).not.toHaveProperty('accessToken');
  });

  it('returns a safe error when Google Calendar fails', async () => {
    vi.spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(new Response(JSON.stringify({ access_token: 'test-access-token' }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ error: { message: 'private upstream detail' } }), { status: 500 }));
    const response = await app.inject({ method: 'POST', url: '/api/calendar/events', headers: { authorization: `Bearer ${token}` }, payload: validPayload });
    expect(response.statusCode).toBe(502);
    expect(response.body).not.toContain('private upstream detail');
    expect(response.json().error).toBe('CALENDAR_SERVICE_UNAVAILABLE');
  });
});
