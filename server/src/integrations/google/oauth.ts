import { env } from '../../config/env.js';

export class GoogleAuthorizationError extends Error {
  constructor() {
    super('Google authorization is unavailable.');
    this.name = 'GoogleAuthorizationError';
  }
}

export class GoogleServiceError extends Error {
  constructor(public readonly status: number) {
    super('A Google service request failed.');
    this.name = 'GoogleServiceError';
  }
}

let cachedAccessToken: { value: string; expiresAt: number } | undefined;

export async function getGoogleAccessToken(): Promise<string> {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60_000) {
    return cachedAccessToken.value;
  }

  if (!env.GMAIL_CLIENT_ID || !env.GMAIL_CLIENT_SECRET || !env.GMAIL_REFRESH_TOKEN) {
    throw new GoogleAuthorizationError();
  }

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: env.GMAIL_CLIENT_ID,
      client_secret: env.GMAIL_CLIENT_SECRET,
      refresh_token: env.GMAIL_REFRESH_TOKEN,
      grant_type: 'refresh_token',
    }),
  });

  if (!response.ok) {
    if (response.status === 400 || response.status === 401 || response.status === 403) {
      throw new GoogleAuthorizationError();
    }
    throw new GoogleServiceError(response.status);
  }

  const result = await response.json() as { access_token?: string; expires_in?: number };
  if (!result.access_token) throw new GoogleAuthorizationError();

  cachedAccessToken = {
    value: result.access_token,
    expiresAt: Date.now() + (result.expires_in ?? 3600) * 1000,
  };
  return result.access_token;
}

export function clearGoogleAccessTokenCacheForTests(): void {
  if (env.NODE_ENV === 'test') cachedAccessToken = undefined;
}
