import cookie from '@fastify/cookie';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import Fastify from 'fastify';
import type { IncomingMessage, ServerResponse } from 'node:http';
import { ZodError } from 'zod';
import { timingSafeEqual } from 'node:crypto';
import { env } from './config/env.js';
import { prisma } from './lib/prisma.js';
import { authRoutes } from './modules/auth/routes.js';
import { documentRoutes } from './modules/documents/routes.js';
import { adminRoutes } from './modules/admin/routes.js';
import { supportRoutes } from './modules/support/routes.js';
import { runReminderCycle, startReminderEngine } from './modules/reminders/engine.js';

export function buildApp() {
  // Start background engine
  if (env.NODE_ENV !== 'test' && env.REMINDER_SCHEDULER_ENABLED) {
    startReminderEngine();
  }

  const app = Fastify({
    logger: { level: env.LOG_LEVEL, redact: ['req.headers.authorization', 'req.headers.cookie', 'res.headers.set-cookie'] },
    requestIdHeader: 'x-request-id',
    trustProxy: env.NODE_ENV !== 'development',
  });

  app.register(helmet, { contentSecurityPolicy: false, global: true });
  app.register(cookie);
  app.register(jwt, { secret: env.JWT_ACCESS_SECRET });
  app.register(rateLimit, { global: false });
  app.register(cors, {
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (env.NODE_ENV === 'development' && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
        return callback(null, true);
      }
      return callback(null, env.webOrigins.includes(origin));
    },
    credentials: true,
    methods: ['GET', 'PUT', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  });

  app.get('/health/live', async () => ({ status: 'ok', version: env.APP_VERSION }));
  app.get('/health/ready', async (_request, reply) => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      return { status: 'ok', database: 'ok', version: env.APP_VERSION };
    } catch {
      return reply.status(503).send({ status: 'unavailable', database: 'unavailable' });
    }
  });

  app.post('/api/internal/reminders/run', async (request, reply) => {
    const supplied = request.headers['x-reminder-cron-secret'];
    const expected = env.REMINDER_CRON_SECRET;
    if (typeof supplied !== 'string' || !expected || supplied.length !== expected.length || !timingSafeEqual(Buffer.from(supplied), Buffer.from(expected))) {
      return reply.status(401).send({ error: 'UNAUTHORIZED', message: 'Invalid scheduler credentials.' });
    }
    await runReminderCycle();
    return reply.status(202).send({ message: 'Reminder cycle completed.' });
  });

  app.register(authRoutes);
  app.register(documentRoutes);
  app.register(adminRoutes);
  app.register(supportRoutes);
  app.setErrorHandler((error, request, reply) => {
    if (error instanceof ZodError) {
      return reply.status(400).send({ error: 'VALIDATION_ERROR', message: 'Request validation failed', details: error.flatten() });
    }
    if (typeof error === 'object' && error !== null && 'statusCode' in error && typeof error.statusCode === 'number' && error.statusCode < 500) {
      const code = 'code' in error && typeof error.code === 'string' ? error.code : 'REQUEST_ERROR';
      const message = 'message' in error && typeof error.message === 'string' ? error.message : 'Request failed.';
      return reply.status(error.statusCode).send({ error: code, message });
    }
    request.log.error(error);
    return reply.status(500).send({ error: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  });

  return app;
}

const app = buildApp();
const ready = app.ready();

/**
 * Vercel detects src/app.ts as the Fastify entrypoint.  Exporting a request
 * handler lets the serverless runtime hand each request to the already-built
 * Fastify application without starting a listening TCP server.
 */
export default async function handler(request: IncomingMessage, response: ServerResponse) {
  await ready;
  app.server.emit('request', request, response);
}
