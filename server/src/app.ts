import cookie from '@fastify/cookie';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import Fastify from 'fastify';
import { ZodError } from 'zod';
import { env } from './config/env.js';
import { prisma } from './lib/prisma.js';
import { authRoutes } from './modules/auth/routes.js';

export function buildApp() {
  const app = Fastify({
    logger: { level: env.LOG_LEVEL, redact: ['req.headers.authorization', 'req.headers.cookie', 'res.headers.set-cookie'] },
    requestIdHeader: 'x-request-id',
    trustProxy: env.NODE_ENV !== 'development',
  });

  app.register(helmet, { contentSecurityPolicy: false, global: true });
  app.register(cookie);
  app.register(jwt, { secret: env.JWT_ACCESS_SECRET });
  app.register(cors, {
    origin: (origin, callback) => callback(null, !origin || env.webOrigins.includes(origin)),
    credentials: true,
  });
  app.register(rateLimit, { global: true, max: 200, timeWindow: '1 minute' });

  app.get('/health/live', async () => ({ status: 'ok', version: env.APP_VERSION }));
  app.get('/health/ready', async (_request, reply) => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      return { status: 'ok', database: 'ok', version: env.APP_VERSION };
    } catch {
      return reply.status(503).send({ status: 'unavailable', database: 'unavailable' });
    }
  });

  app.register(authRoutes);


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
