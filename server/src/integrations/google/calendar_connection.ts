import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'node:crypto';
import { env } from '../../config/env.js';
import { prisma } from '../../lib/prisma.js';
import {
  getCachedGoogleAccessToken,
  GoogleAuthorizationError,
  GoogleCalendarConfigurationError,
  GoogleCalendarConnectionRequiredError,
  GoogleServiceError,
} from './oauth.js';

const calendarScope = 'https://www.googleapis.com/auth/calendar.events';

function requireCalendarConfiguration() {
  if (!env.GOOGLE_CALENDAR_CLIENT_ID || !env.GOOGLE_CALENDAR_CLIENT_SECRET || !env.GOOGLE_CALENDAR_REDIRECT_URI || !env.GOOGLE_TOKEN_ENCRYPTION_KEY) {
    throw new GoogleCalendarConfigurationError();
  }
  return { clientId: env.GOOGLE_CALENDAR_CLIENT_ID, clientSecret: env.GOOGLE_CALENDAR_CLIENT_SECRET, redirectUri: env.GOOGLE_CALENDAR_REDIRECT_URI };
}

function encryptionKey(): Buffer {
  if (!env.GOOGLE_TOKEN_ENCRYPTION_KEY) throw new GoogleCalendarConfigurationError();
  const key = Buffer.from(env.GOOGLE_TOKEN_ENCRYPTION_KEY, 'base64url');
  if (key.length !== 32) throw new GoogleCalendarConfigurationError();
  return key;
}

export function encryptGoogleCalendarSecret(value: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', encryptionKey(), iv);
  const ciphertext = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  return ['v1', iv.toString('base64url'), cipher.getAuthTag().toString('base64url'), ciphertext.toString('base64url')].join('.');
}

export function decryptGoogleCalendarSecret(value: string): string {
  const [version, ivValue, tagValue, ciphertextValue] = value.split('.');
  if (version !== 'v1' || !ivValue || !tagValue || !ciphertextValue) throw new GoogleAuthorizationError();
  try {
    const decipher = createDecipheriv('aes-256-gcm', encryptionKey(), Buffer.from(ivValue, 'base64url'));
    decipher.setAuthTag(Buffer.from(tagValue, 'base64url'));
    return Buffer.concat([decipher.update(Buffer.from(ciphertextValue, 'base64url')), decipher.final()]).toString('utf8');
  } catch (error) {
    if (error instanceof GoogleCalendarConfigurationError) throw error;
    throw new GoogleAuthorizationError();
  }
}

export function hashGoogleCalendarState(state: string): string {
  return createHash('sha256').update(state).digest('base64url');
}

export function createGoogleCalendarAuthorizationUrl(state: string, codeVerifier: string): string {
  const config = requireCalendarConfiguration();
  const codeChallenge = createHash('sha256').update(codeVerifier).digest('base64url');
  const authorizationUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
  authorizationUrl.search = new URLSearchParams({
    client_id: config.clientId,
    redirect_uri: config.redirectUri,
    response_type: 'code',
    access_type: 'offline',
    prompt: 'consent',
    include_granted_scopes: 'true',
    scope: calendarScope,
    state,
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
  }).toString();
  return authorizationUrl.toString();
}

export async function exchangeGoogleCalendarAuthorizationCode(code: string, codeVerifier: string): Promise<string> {
  const config = requireCalendarConfiguration();
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ code, client_id: config.clientId, client_secret: config.clientSecret, redirect_uri: config.redirectUri, code_verifier: codeVerifier, grant_type: 'authorization_code' }),
  });
  if (!response.ok) {
    if (response.status === 400 || response.status === 401 || response.status === 403) throw new GoogleAuthorizationError();
    throw new GoogleServiceError(response.status);
  }
  const token = await response.json() as { refresh_token?: string };
  if (!token.refresh_token) throw new GoogleAuthorizationError();
  return token.refresh_token;
}

export async function getUserGoogleCalendarAccessToken(userId: string): Promise<string> {
  const connection = await prisma.googleCalendarConnection.findUnique({ where: { userId }, select: { id: true, encryptedRefreshToken: true } });
  if (!connection) throw new GoogleCalendarConnectionRequiredError();
  const config = requireCalendarConfiguration();
  return getCachedGoogleAccessToken(`calendar:${connection.id}`, {
    clientId: config.clientId,
    clientSecret: config.clientSecret,
    refreshToken: decryptGoogleCalendarSecret(connection.encryptedRefreshToken),
  });
}

export async function revokeGoogleCalendarConnection(encryptedRefreshToken: string): Promise<void> {
  try {
    await fetch('https://oauth2.googleapis.com/revoke', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ token: decryptGoogleCalendarSecret(encryptedRefreshToken) }),
    });
  } catch {
    // Local removal still protects the user when Google's revoke endpoint is unavailable.
  }
}
