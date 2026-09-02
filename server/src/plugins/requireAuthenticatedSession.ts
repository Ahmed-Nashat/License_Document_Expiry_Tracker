import type { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../lib/prisma.js';

interface JwtPayload {
  userId: string;
  sessionId: string;
  role: string;
}

export async function requireAuthenticatedSession(request: FastifyRequest, reply: FastifyReply): Promise<JwtPayload | null> {
  try {
    const payload = await request.jwtVerify<JwtPayload>();
    const session = await prisma.userSession.findUnique({
      where: { id: payload.sessionId },
      select: {
        userId: true,
        revokedAt: true,
        expiresAt: true,
        user: { select: { suspendedAt: true } },
      },
    });

    if (!session || session.userId !== payload.userId || session.revokedAt || session.expiresAt <= new Date() || session.user.suspendedAt) {
      await reply.status(401).send({ error: 'SESSION_EXPIRED', message: 'Please sign in again.' });
      return null;
    }

    request.user = payload;
    return payload;
  } catch {
    await reply.status(401).send({ error: 'UNAUTHORIZED', message: 'Authentication required.' });
    return null;
  }
}
