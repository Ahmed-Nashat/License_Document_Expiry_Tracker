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

export class GoogleCalendarConnectionRequiredError extends Error {
  constructor() {
    super('Google Calendar is not connected.');
    this.name = 'GoogleCalendarConnectionRequiredError';
  }
}

export class GoogleCalendarConfigurationError extends Error {
  constructor() {
    super('Google Calendar is not configured.');
    this.name = 'GoogleCalendarConfigurationError';
  }
}

interface TokenCredentials {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
}

const cachedAccessTokens = new Map<string, { value: string; expiresAt: number }>();

async function refreshGoogleAccessToken(credentials: TokenCredentials): Promise<{ value: string; expiresAt: number }> {
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: credentials.clientId,
      client_secret: credentials.clientSecret,
      refresh_token: credentials.refreshToken,
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
  return { value: result.access_token, expiresAt: Date.now() + (result.expires_in ?? 3600) * 1000 };
}

export async function getCachedGoogleAccessToken(cacheKey: string, credentials: TokenCredentials): Promise<string> {
  const cached = cachedAccessTokens.get(cacheKey);
  if (cached && cached.expiresAt > Date.now() + 60_000) return cached.value;
  const next = await refreshGoogleAccessToken(credentials);
  cachedAccessTokens.set(cacheKey, next);
  return next.value;
}

export async function getGoogleAccessToken(): Promise<string> {
  if (!env.GMAIL_CLIENT_ID || !env.GMAIL_CLIENT_SECRET || !env.GMAIL_REFRESH_TOKEN) {
    throw new GoogleAuthorizationError();
  }
  return getCachedGoogleAccessToken('gmail-owner', {
    clientId: env.GMAIL_CLIENT_ID,
    clientSecret: env.GMAIL_CLIENT_SECRET,
    refreshToken: env.GMAIL_REFRESH_TOKEN,
  });
}

export function clearGoogleAccessTokenCacheForTests(): void {
  if (env.NODE_ENV === 'test') cachedAccessTokens.clear();
}
