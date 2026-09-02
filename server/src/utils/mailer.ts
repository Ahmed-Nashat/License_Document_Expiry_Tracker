import { env } from '../config/env.js';

function sender() {
  if (!env.EMAIL_FROM) throw new Error('EMAIL_FROM is required before sending email.');
  const namedSender = /^([^<>\r\n]+)<([^<>\s@]+@[^<>\s@]+\.[^<>\s@]+)>$/.exec(env.EMAIL_FROM);
  return namedSender
    ? { name: namedSender[1].trim(), email: namedSender[2] }
    : { name: 'DueNest', email: env.EMAIL_FROM };
}

export async function sendEmail({ to, subject, html }: { to: string; subject: string; html: string }) {
  if (env.NODE_ENV !== 'production' && !env.BREVO_API_KEY) {
    return { id: 'development-email-skipped' };
  }

  const response = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'api-key': env.BREVO_API_KEY!,
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      sender: sender(),
      to: [{ email: to }],
      subject,
      htmlContent: html,
    }),
  });
  if (!response.ok) throw new Error(`Email delivery failed with status ${response.status}.`);
  const result = await response.json() as { messageId: string };
  return { id: result.messageId };
}
