import { resolve } from 'node:path';
import dotenv from 'dotenv';
dotenv.config();
dotenv.config({ path: resolve(process.cwd(), '../.env') });
import { z } from 'zod';

const booleanFromEnvironment = z.enum(['true', 'false']).default('false').transform((value) => value === 'true');
const senderAddress = z.string().trim().min(3).max(320).refine(
  (value) => /^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$/.test(value) || /^[^<>\r\n]+<[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+>$/.test(value),
  'EMAIL_FROM must be an email address or a display name with an email address.',
);

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'staging', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  HOST: z.string().default('127.0.0.1'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  APP_VERSION: z.string().default('local'),
  WEB_ORIGINS: z.string().default('http://localhost:3001'),
  DATABASE_URL: z.string().url(),
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  ACCESS_TOKEN_TTL_MINUTES: z.coerce.number().int().min(5).max(60).default(15),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().min(1).max(90).default(30),
  COOKIE_SECURE: booleanFromEnvironment,
  COOKIE_SAME_SITE: z.enum(['lax', 'none', 'strict']).default('lax'),
  COOKIE_DOMAIN: z.string().optional(),
  GMAIL_CLIENT_ID: z.string().min(10).optional(),
  GMAIL_CLIENT_SECRET: z.string().min(10).optional(),
  GMAIL_REFRESH_TOKEN: z.string().min(10).optional(),
  EMAIL_FROM: senderAddress.optional(),
  GOOGLE_CALENDAR_CLIENT_ID: z.string().min(10).optional(),
  GOOGLE_CALENDAR_CLIENT_SECRET: z.string().min(10).optional(),
  GOOGLE_CALENDAR_REDIRECT_URI: z.string().url().optional(),
  GOOGLE_TOKEN_ENCRYPTION_KEY: z.string().min(32).optional(),
  REMINDER_CRON_SECRET: z.string().min(32).optional(),
  REMINDER_SCHEDULER_ENABLED: booleanFromEnvironment,
}).superRefine((value, context) => {
  if (value.NODE_ENV !== 'production') return;

  for (const key of ['GMAIL_CLIENT_ID', 'GMAIL_CLIENT_SECRET', 'GMAIL_REFRESH_TOKEN', 'EMAIL_FROM', 'REMINDER_CRON_SECRET'] as const) {
    if (!value[key]) {
      context.addIssue({ code: z.ZodIssueCode.custom, path: [key], message: `${key} is required in production.` });
    }
  }

  const origins = value.WEB_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean);
  if (!origins.length || origins.some((origin) => {
    try {
      const url = new URL(origin);
      return url.protocol !== 'https:' || url.hostname === 'localhost' || url.hostname === '127.0.0.1';
    } catch {
      return true;
    }
  })) {
    context.addIssue({ code: z.ZodIssueCode.custom, path: ['WEB_ORIGINS'], message: 'Production WEB_ORIGINS must contain only HTTPS public origins.' });
  }
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  throw new Error(`Invalid environment configuration: ${parsed.error.issues.map((issue) => issue.path.join('.')).join(', ')}`);
}

export const env = {
  ...parsed.data,
  COOKIE_SECURE: parsed.data.NODE_ENV === 'production' ? true : parsed.data.COOKIE_SECURE,
  COOKIE_SAME_SITE: parsed.data.NODE_ENV === 'production' ? 'none' : parsed.data.COOKIE_SAME_SITE,
  webOrigins: parsed.data.WEB_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean),
};
