import { FastifyRequest, FastifyReply } from 'fastify';
import { requireAuthenticatedSession } from './requireAuthenticatedSession.js';

/**
 * Middleware to protect admin routes.
 */
export async function requireAdmin(request: FastifyRequest, reply: FastifyReply) {
  const payload = await requireAuthenticatedSession(request, reply);
  if (!payload) return;
  if (payload.role !== 'ADMIN') {
    request.log.warn({ userId: payload.userId }, 'Forbidden: Non-admin attempted to access admin route');
    return reply.status(403).send({ error: 'FORBIDDEN', message: 'Admin access required' });
  }
}
