import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { createAuditLog } from '../../utils/auditLogger.js';
import { requireAuthenticatedSession } from '../../plugins/requireAuthenticatedSession.js';

interface JwtPayload {
  userId: string;
  sessionId: string;
  role: string;
}

export async function supportRoutes(app: FastifyInstance) {
  // Consumer ticket creation route
  app.post('/api/support/tickets', {
    preHandler: async (request, reply) => {
      await requireAuthenticatedSession(request, reply);
    }
  }, async (request, reply) => {
    const user = request.user as JwtPayload;
    const input = z.object({
      category: z.enum(['ACCOUNT_ACCESS', 'REMINDER_DELIVERY', 'PRIVACY_DELETION', 'OTHER']),
      subject: z.string().min(5).max(200),
      description: z.string().min(10).max(5000),
    }).parse(request.body);

    const dbUser = await prisma.user.findUnique({ where: { id: user.userId } });
    if (!dbUser) return reply.status(404).send({ error: 'NOT_FOUND', message: 'User not found' });

    const ticket = await prisma.supportTicket.create({
      data: {
        requesterEmail: dbUser.email,
        userId: user.userId,
        category: input.category,
        subject: input.subject,
        description: input.description,
        status: 'OPEN',
      },
    });

    await createAuditLog(app, {
      actorId: user.userId,
      actorType: 'USER',
      action: 'SUPPORT_TICKET_CREATED',
      targetId: ticket.id,
      ipAddress: request.ip,
      requestId: request.id,
    });

    return reply.status(201).send({ message: 'Ticket created', ticketId: ticket.id });
  });
}

