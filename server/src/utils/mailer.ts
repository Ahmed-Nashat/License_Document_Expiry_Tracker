import { env } from '../config/env.js';
import { getGoogleAccessToken, GoogleServiceError } from '../integrations/google/oauth.js';

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

  const accessToken = await getGoogleAccessToken();
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
  if (!response.ok) throw new GoogleServiceError(response.status);
  const result = await response.json() as { id: string };
  return { id: result.id };
}

function formatSenderHeader() {
  const value = sender();
  return value.name === 'DueNest' ? value.email : `${value.name} <${value.email}>`;
}

function base64UrlEncode(value: string) {
  return Buffer.from(value, 'utf8').toString('base64').replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}
