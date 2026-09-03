import { randomBytes } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { fromZonedTime } from 'date-fns-tz';
import { z } from 'zod';
import {
  createGoogleCalendarAuthorizationUrl,
  decryptGoogleCalendarSecret,
  encryptGoogleCalendarSecret,
  exchangeGoogleCalendarAuthorizationCode,
  hashGoogleCalendarState,
  revokeGoogleCalendarConnection,
} from '../../integrations/google/calendar_connection.js';
import {
  GoogleAuthorizationError,
  GoogleCalendarConfigurationError,
  GoogleCalendarConnectionRequiredError,
  GoogleServiceError,
} from '../../integrations/google/oauth.js';
import { env } from '../../config/env.js';
import { prisma } from '../../lib/prisma.js';
import { requireAuthenticatedSession } from '../../plugins/requireAuthenticatedSession.js';
import { createGoogleCalendarEvent } from './service.js';

interface JwtPayload {
  userId: string;
  sessionId: string;
}

const localDateTime = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,3})?)?$/;
const offsetDateTime = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,3})?)?(?:Z|[+-]\d{2}:\d{2})$/;
const callbackQuery = z.object({ code: z.string().min(1).optional(), state: z.string().min(32).max(200), error: z.string().max(100).optional() });

function validTimeZone(value: string): boolean {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: value }).format();
    return true;
  } catch {
    return false;
  }
}

function validCalendarDateTime(value: string): boolean {
  if (!localDateTime.test(value) && !offsetDateTime.test(value)) return false;
  const match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?/.exec(value);
  if (!match) return false;
  const [, year, month, day, hour, minute, second = '0'] = match;
  const check = new Date(Date.UTC(Number(year), Number(month) - 1, Number(day), Number(hour), Number(minute), Number(second)));
  return check.getUTCFullYear() === Number(year)
    && check.getUTCMonth() === Number(month) - 1
    && check.getUTCDate() === Number(day)
    && check.getUTCHours() === Number(hour)
    && check.getUTCMinutes() === Number(minute)
    && check.getUTCSeconds() === Number(second)
    && !Number.isNaN(Date.parse(value));
}

const calendarEventSchema = z.object({
  title: z.string().trim().min(1).max(120),
  description: z.string().trim().max(1000).default(''),
  start: z.string().trim().max(40).refine(validCalendarDateTime, 'A valid ISO date-time is required.'),
  end: z.string().trim().max(40).refine(validCalendarDateTime, 'A valid ISO date-time is required.'),
  timeZone: z.string().trim().min(1).max(100).refine(validTimeZone, 'A valid IANA time zone is required.'),
});

function toUtc(value: string, timeZone: string): Date {
  return offsetDateTime.test(value) ? new Date(value) : fromZonedTime(value, timeZone);
}

function returnUrlFor(origin: string | undefined): string {
  if (!origin || !env.webOrigins.includes(origin)) throw new GoogleCalendarConfigurationError();
  const url = new URL(origin);
  return new URL('/', url).toString();
}

function callbackRedirect(returnUrl: string, result: 'connected' | 'cancelled' | 'error'): string {
  const url = new URL(returnUrl);
  url.searchParams.set('calendar', result);
  return url.toString();
}

export async function calendarRoutes(app: FastifyInstance) {
  app.get('/api/calendar/connection', {
    preHandler: async (request, reply) => requireAuthenticatedSession(request, reply),
  }, async (request) => {
    const connection = await prisma.googleCalendarConnection.findUnique({
      where: { userId: (request.user as JwtPayload).userId },
      select: { createdAt: true, updatedAt: true },
    });
    return { connected: Boolean(connection), connectedAt: connection?.createdAt ?? null, updatedAt: connection?.updatedAt ?? null };
  });

  app.post('/api/calendar/connection/authorize', {
    config: { rateLimit: { max: 5, timeWindow: '10 minutes' } },
    preHandler: async (request, reply) => requireAuthenticatedSession(request, reply),
  }, async (request, reply) => {
    const userId = (request.user as JwtPayload).userId;
    const state = randomBytes(32).toString('base64url');
    const codeVerifier = randomBytes(48).toString('base64url');
    const returnUrl = returnUrlFor(request.headers.origin);
    const authorizationUrl = createGoogleCalendarAuthorizationUrl(state, codeVerifier);
    await prisma.$transaction([
      prisma.googleCalendarOAuthAttempt.deleteMany({ where: { userId, expiresAt: { lt: new Date() } } }),
      prisma.googleCalendarOAuthAttempt.create({
        data: {
          userId,
          stateHash: hashGoogleCalendarState(state),
          encryptedCodeVerifier: encryptGoogleCalendarSecret(codeVerifier),
          returnUrl,
          expiresAt: new Date(Date.now() + 10 * 60_000),
        },
      }),
    ]);
    return reply.status(200).send({ authorizationUrl });
  });

  app.get('/api/calendar/oauth/callback', async (request, reply) => {
    const query = callbackQuery.parse(request.query);
    const attempt = await prisma.googleCalendarOAuthAttempt.findUnique({ where: { stateHash: hashGoogleCalendarState(query.state) } });
    if (!attempt || attempt.expiresAt <= new Date()) {
      if (attempt) await prisma.googleCalendarOAuthAttempt.delete({ where: { id: attempt.id } });
      return reply.status(400).type('text/plain').send('Google Calendar authorization expired. Return to DueNest and try again.');
    }
    if (query.error || !query.code) {
      await prisma.googleCalendarOAuthAttempt.delete({ where: { id: attempt.id } });
      return reply.redirect(callbackRedirect(attempt.returnUrl, 'cancelled'));
    }

    try {
      const refreshToken = await exchangeGoogleCalendarAuthorizationCode(query.code, decryptGoogleCalendarSecret(attempt.encryptedCodeVerifier));
      await prisma.$transaction([
        prisma.googleCalendarConnection.upsert({
          where: { userId: attempt.userId },
          create: { userId: attempt.userId, encryptedRefreshToken: encryptGoogleCalendarSecret(refreshToken) },
          update: { encryptedRefreshToken: encryptGoogleCalendarSecret(refreshToken) },
        }),
        prisma.googleCalendarOAuthAttempt.delete({ where: { id: attempt.id } }),
      ]);
      return reply.redirect(callbackRedirect(attempt.returnUrl, 'connected'));
    } catch (error) {
      request.log.warn({ err: error }, 'Google Calendar connection could not be completed.');
      return reply.redirect(callbackRedirect(attempt.returnUrl, 'error'));
    }
  });

  app.delete('/api/calendar/connection', {
    preHandler: async (request, reply) => requireAuthenticatedSession(request, reply),
  }, async (request, reply) => {
    const connection = await prisma.googleCalendarConnection.findUnique({
      where: { userId: (request.user as JwtPayload).userId },
      select: { id: true, encryptedRefreshToken: true },
    });
    if (!connection) return reply.status(204).send();
    await revokeGoogleCalendarConnection(connection.encryptedRefreshToken);
    await prisma.googleCalendarConnection.delete({ where: { id: connection.id } });
    return reply.status(204).send();
  });

  app.post('/api/calendar/events', {
    config: { rateLimit: { max: 10, timeWindow: '1 minute' } },
    preHandler: async (request, reply) => requireAuthenticatedSession(request, reply),
  }, async (request, reply) => {
    const input = calendarEventSchema.parse(request.body);
    const start = toUtc(input.start, input.timeZone);
    const end = toUtc(input.end, input.timeZone);
    if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
      return reply.status(400).send({ error: 'VALIDATION_ERROR', message: 'Start and end must be valid dates.' });
    }
    if (end <= start) {
      return reply.status(400).send({ error: 'INVALID_DATE_RANGE', message: 'End must be after start.' });
    }

    try {
      const event = await createGoogleCalendarEvent({ userId: (request.user as JwtPayload).userId, ...input, start, end });
      return reply.status(event.created ? 201 : 200).send(event);
    } catch (error) {
      if (error instanceof GoogleCalendarConnectionRequiredError) {
        return reply.status(409).send({ error: 'CALENDAR_CONNECTION_REQUIRED', message: 'Connect your Google Calendar before adding an event.' });
      }
      if (error instanceof GoogleCalendarConfigurationError) {
        return reply.status(503).send({ error: 'CALENDAR_NOT_CONFIGURED', message: 'Google Calendar is not available yet. Please try again later.' });
      }
      if (error instanceof GoogleAuthorizationError) {
        return reply.status(403).send({ error: 'CALENDAR_AUTHORIZATION_REQUIRED', message: 'Your Google Calendar connection needs to be renewed.' });
      }
      if (error instanceof GoogleServiceError) {
        request.log.warn({ googleStatus: error.status }, 'Google Calendar event creation failed.');
        return reply.status(502).send({ error: 'CALENDAR_SERVICE_UNAVAILABLE', message: 'Google Calendar could not create the event. Please try again.' });
      }
      throw error;
    }
  });
}
