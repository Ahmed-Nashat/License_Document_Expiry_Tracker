import { env } from '../config/env.js';

function sender() {
  if (!env.EMAIL_FROM) throw new Error('EMAIL_FROM is required before sending email.');
  const namedSender = /^([^<>\r\n]+)<([^<>\s@]+@[^<>\s@]+\.[^<>\s@]+)>$/.exec(env.EMAIL_FROM);
  return namedSender
    ? { name: namedSender[1]!.trim(), email: namedSender[2]! }
    : { name: 'DueNest', email: env.EMAIL_FROM };
}

export async function sendEmail({ to, subject, html }: { to: string; subject: string; html: string }) {
  const hasGmailConfig = Boolean(env.GMAIL_CLIENT_ID && env.GMAIL_CLIENT_SECRET && env.GMAIL_REFRESH_TOKEN && env.EMAIL_FROM);
  if (env.NODE_ENV !== 'production' && !hasGmailConfig) {
    return { id: 'development-email-skipped' };
  }

  if (!hasGmailConfig) throw new Error('Gmail email configuration is incomplete.');

  const accessToken = await getAccessToken();
  const message = [
    `From: ${formatSenderHeader()}`,
    `To: ${to}`,
    `Subject: ${subject}`,
    'MIME-Version: 1.0',
    'Content-Type: text/html; charset=UTF-8',
    'Content-Transfer-Encoding: 8bit',
    '',
    html,
  ].join('\r\n');

  const response = await fetch('https://gmail.googleapis.com/gmail/v1/users/me/messages/send', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ raw: base64UrlEncode(message) }),
  });
  if (!response.ok) throw await googleRequestError('Gmail message delivery', response);
  const result = await response.json() as { id: string };
  return { id: result.id };
}

let cachedAccessToken: { value: string; expiresAt: number } | undefined;

async function getAccessToken() {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60_000) return cachedAccessToken.value;
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: env.GMAIL_CLIENT_ID!,
      client_secret: env.GMAIL_CLIENT_SECRET!,
      refresh_token: env.GMAIL_REFRESH_TOKEN!,
      grant_type: 'refresh_token',
    }),
  });
  if (!response.ok) throw await googleRequestError('Google authorization', response);
  const result = await response.json() as { access_token?: string; expires_in?: number };
  if (!result.access_token) throw new Error('Google authorization did not return an access token.');
  cachedAccessToken = { value: result.access_token, expiresAt: Date.now() + (result.expires_in ?? 3600) * 1000 };
  return result.access_token;
}

function formatSenderHeader() {
  const value = sender();
  return value.name === 'DueNest' ? value.email : `${value.name} <${value.email}>`;
}

function base64UrlEncode(value: string) {
  return Buffer.from(value, 'utf8').toString('base64').replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}

async function googleRequestError(operation: string, response: Response) {
  const payload = await response.json().catch(() => undefined) as {
    error?: string | { message?: string; status?: string };
    error_description?: string;
  } | undefined;
  const reason = typeof payload?.error === 'string'
    ? payload.error_description ?? payload.error
    : payload?.error?.message ?? payload?.error?.status;
  return new Error(`${operation} failed with status ${response.status}${reason ? `: ${reason}` : ''}.`);
}
