import nodemailer from 'nodemailer';
import { env } from '../config/env.js';

let transporter: nodemailer.Transporter | null = null;

export async function getMailer() {
  if (transporter) return transporter;

  // For development, we'll use Ethereal Email which intercepts emails and provides a preview URL
  if (env.NODE_ENV === 'production') {
    transporter = nodemailer.createTransport({
      host: env.SMTP_HOST,
      port: env.SMTP_PORT ? parseInt(env.SMTP_PORT) : 587,
      secure: env.SMTP_PORT === '465',
      auth: {
        user: env.SMTP_USER,
        pass: env.SMTP_PASS,
      },
    });
  } else {
    // Generate a test account on the fly if no SMTP credentials exist
    if (!env.SMTP_USER) {
      const testAccount = await nodemailer.createTestAccount();
      transporter = nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass,
        },
      });
      console.log('[Mailer] Development test account created.');
    } else {
       transporter = nodemailer.createTransport({
        host: env.SMTP_HOST || 'smtp.ethereal.email',
        port: env.SMTP_PORT ? parseInt(env.SMTP_PORT) : 587,
        secure: env.SMTP_PORT === '465',
        auth: {
          user: env.SMTP_USER,
          pass: env.SMTP_PASS,
        },
      });
    }
  }

  return transporter;
}

export async function sendEmail({ to, subject, html }: { to: string; subject: string; html: string }) {
  const mailer = await getMailer();
  
  const info = await mailer.sendMail({
    from: '"DueNest Reminders" <no-reply@duenest.app>',
    to,
    subject,
    html,
  });

  if (env.NODE_ENV !== 'production') {
    console.log('[Mailer] Development email sent.');
  }

  return info;
}
