import { env } from '../config/env.js';

export async function sendEmail({ to, subject, html }: { to: string; subject: string; html: string }) {
  if (env.NODE_ENV !== 'production' && !env.RESEND_API_KEY) {
    return { id: 'development-email-skipped' };
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ from: env.EMAIL_FROM, to: [to], subject, html }),
  });
  if (!response.ok) throw new Error(`Email delivery failed with status ${response.status}.`);
  return response.json() as Promise<{ id: string }>;
}
