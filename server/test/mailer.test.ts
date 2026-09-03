import { beforeEach, describe, expect, it, vi } from 'vitest';

describe('Gmail delivery with shared Google authorization', async () => {
  const { sendEmail } = await import('../src/utils/mailer.js');
  const { clearGoogleAccessTokenCacheForTests } = await import('../src/integrations/google/oauth.js');

  beforeEach(() => {
    vi.restoreAllMocks();
    clearGoogleAccessTokenCacheForTests();
  });

  it('still refreshes an access token and sends Gmail messages', async () => {
    const googleFetch = vi.spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(new Response(JSON.stringify({ access_token: 'test-access-token', expires_in: 3600 }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ id: 'gmail-message-1' }), { status: 200 }));

    const result = await sendEmail({
      to: 'recipient@example.com',
      subject: 'DueNest test',
      html: '<p>Safe test message</p>',
    });

    expect(result).toEqual({ id: 'gmail-message-1' });
    expect(googleFetch).toHaveBeenCalledTimes(2);
    expect(googleFetch.mock.calls[0]?.[0]).toBe('https://oauth2.googleapis.com/token');
    expect(googleFetch.mock.calls[1]?.[0]).toBe('https://gmail.googleapis.com/gmail/v1/users/me/messages/send');
  });
});
