import { FastifyRequest, FastifyReply } from 'fastify';

interface JwtPayload {
  userId: string;
  sessionId: string;
  role: string;
}

/**
 * Middleware to protect admin routes.
 */
export async function requireAdmin(request: FastifyRequest, reply: FastifyReply) {
  try {
    const payload = await request.jwtVerify() as JwtPayload;
    if (payload.role !== 'ADMIN') {
      request.log.warn({ userId: payload.userId }, 'Forbidden: Non-admin attempted to access admin route');
      return reply.status(403).send({ error: 'FORBIDDEN', message: 'Admin access required' });
    }
    // We attach the user to the request for subsequent handlers
    request.user = payload;
  } catch {
    return reply.status(401).send({ error: 'UNAUTHORIZED', message: 'Authentication required' });
  }
}
