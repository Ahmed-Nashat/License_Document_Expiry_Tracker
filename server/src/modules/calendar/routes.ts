import type { FastifyInstance } from 'fastify';
import { fromZonedTime } from 'date-fns-tz';
import { z } from 'zod';
import { GoogleAuthorizationError, GoogleServiceError } from '../../integrations/google/oauth.js';
import { requireAuthenticatedSession } from '../../plugins/requireAuthenticatedSession.js';
import { createGoogleCalendarEvent } from './service.js';

interface JwtPayload {
  userId: string;
  sessionId: string;
}

const localDateTime = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,3})?)?$/;
const offsetDateTime = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,3})?)?(?:Z|[+-]\d{2}:\d{2})$/;

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

export async function calendarRoutes(app: FastifyInstance) {
  app.post('/api/calendar/events', {
    config: { rateLimit: { max: 10, timeWindow: '1 minute' } },
    preHandler: async (request, reply) => {
      await requireAuthenticatedSession(request, reply);
    },
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
      const event = await createGoogleCalendarEvent({
        userId: (request.user as JwtPayload).userId,
        ...input,
        start,
        end,
      });
      return reply.status(event.created ? 201 : 200).send(event);
    } catch (error) {
      if (error instanceof GoogleAuthorizationError) {
        return reply.status(503).send({
          error: 'CALENDAR_AUTHORIZATION_REQUIRED',
          message: 'Google Calendar authorization is missing. Please reconnect the application owner account.',
        });
      }
      if (error instanceof GoogleServiceError) {
        request.log.warn({ googleStatus: error.status }, 'Google Calendar event creation failed.');
        return reply.status(502).send({
          error: 'CALENDAR_SERVICE_UNAVAILABLE',
          message: 'Google Calendar could not create the event. Please try again.',
        });
      }
      throw error;
    }
  });
}
