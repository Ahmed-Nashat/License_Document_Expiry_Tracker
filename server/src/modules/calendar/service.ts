import { createHash } from 'node:crypto';
import { getUserGoogleCalendarAccessToken } from '../../integrations/google/calendar_connection.js';
import { GoogleAuthorizationError, GoogleServiceError } from '../../integrations/google/oauth.js';

interface CalendarEventInput {
  userId: string;
  title: string;
  description: string;
  start: Date;
  end: Date;
  timeZone: string;
}

interface GoogleCalendarEvent {
  id?: string;
  htmlLink?: string;
}

export interface CreatedCalendarEvent {
  eventId: string;
  eventLink: string;
  created: boolean;
}

function eventIdFor(input: CalendarEventInput): string {
  return createHash('sha256')
    .update(JSON.stringify({
      userId: input.userId,
      title: input.title,
      description: input.description,
      start: input.start.toISOString(),
      end: input.end.toISOString(),
      timeZone: input.timeZone,
    }))
    .digest('hex');
}

function safeEvent(event: GoogleCalendarEvent, created: boolean): CreatedCalendarEvent {
  if (!event.id || !event.htmlLink) throw new GoogleServiceError(502);
  let link: URL;
  try {
    link = new URL(event.htmlLink);
  } catch {
    throw new GoogleServiceError(502);
  }
  if (link.protocol !== 'https:') throw new GoogleServiceError(502);
  return { eventId: event.id, eventLink: link.toString(), created };
}

async function calendarRequest(userId: string, url: string, init?: RequestInit): Promise<Response> {
  const accessToken = await getUserGoogleCalendarAccessToken(userId);
  return fetch(url, {
    ...init,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      ...(init?.body ? { 'Content-Type': 'application/json' } : {}),
      ...init?.headers,
    },
  });
}

function throwCalendarError(response: Response): never {
  if (response.status === 401 || response.status === 403) {
    throw new GoogleAuthorizationError();
  }
  throw new GoogleServiceError(response.status);
}

export async function createGoogleCalendarEvent(input: CalendarEventInput): Promise<CreatedCalendarEvent> {
  const eventId = eventIdFor(input);
  const eventUrl = `https://www.googleapis.com/calendar/v3/calendars/primary/events/${eventId}`;
  const response = await calendarRequest(input.userId,
    'https://www.googleapis.com/calendar/v3/calendars/primary/events?sendUpdates=none',
    {
      method: 'POST',
      body: JSON.stringify({
        id: eventId,
        summary: input.title,
        description: input.description,
        start: { dateTime: input.start.toISOString(), timeZone: input.timeZone },
        end: { dateTime: input.end.toISOString(), timeZone: input.timeZone },
        extendedProperties: { private: { source: 'deunest' } },
      }),
    },
  );

  if (response.status === 409) {
    const existingResponse = await calendarRequest(input.userId, eventUrl);
    if (!existingResponse.ok) throwCalendarError(existingResponse);
    return safeEvent(await existingResponse.json() as GoogleCalendarEvent, false);
  }

  if (!response.ok) throwCalendarError(response);
  return safeEvent(await response.json() as GoogleCalendarEvent, true);
}
