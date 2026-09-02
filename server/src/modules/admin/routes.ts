import { FastifyInstance } from 'fastify';
import { prisma } from '../../lib/prisma.js';
import { requireAdmin } from '../../plugins/requireAdmin.js';
import { createAuditLog } from '../../utils/auditLogger.js';

interface JwtPayload {
  userId: string;
  sessionId: string;
  role: string;
}

export async function adminRoutes(app: FastifyInstance) {
  // Protect all routes in this plugin
  app.addHook('preHandler', async (request, reply) => {
    await requireAdmin(request, reply);
  });

  // GET /api/admin/users - Search and list users
  app.get('/api/admin/users', async (request, reply) => {
    const query = request.query as { search?: string };
    const where = query.search
      ? {
          OR: [
            { email: { contains: query.search.trim(), mode: 'insensitive' as const } },
            { displayName: { contains: query.search.trim(), mode: 'insensitive' as const } },
          ],
        }
      : {};

    const users = await prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 50,
      select: {
        id: true,
        email: true,
        displayName: true,
        role: true,
        createdAt: true,
        _count: {
          select: { documents: true, sessions: { where: { revokedAt: null, expiresAt: { gt: new Date() } } } },
        },
      },
    });

    return reply.status(200).send(users);
  });

  // POST /api/admin/users/:id/sessions/revoke - Force sign out a user
  app.post('/api/admin/users/:id/sessions/revoke', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const { id: targetUserId } = request.params as { id: string };

    const targetUser = await prisma.user.findUnique({ where: { id: targetUserId } });
    if (!targetUser) {
      return reply.status(404).send({ error: 'NOT_FOUND', message: 'User not found.' });
    }

    await prisma.userSession.updateMany({
      where: { userId: targetUserId, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await createAuditLog(app, {
      actorId: admin.userId,
      action: 'REVOKE_ALL_SESSIONS',
      targetId: targetUserId,
      reason: 'Admin forced sign out',
      ipAddress: request.ip,
    });

    return reply.status(200).send({ message: 'All active sessions revoked for user.' });
  });

  // GET /api/admin/audit-logs - View system audit logs
  app.get('/api/admin/audit-logs', async (request, reply) => {
    const logs = await prisma.auditLog.findMany({
      orderBy: { timestamp: 'desc' },
      take: 100,
    });

    return reply.status(200).send(logs);
  });

  // GET /api/admin/metrics - View site analytics
  app.get('/api/admin/metrics', async (request, reply) => {
    const [
      usersTotal,
      ageRanges,
      genders,
      docsTotal,
      docTypes,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.groupBy({ by: ['ageRange'], _count: { _all: true } }),
      prisma.user.groupBy({ by: ['gender'], _count: { _all: true } }),
      prisma.document.count(),
      prisma.document.groupBy({ by: ['type'], _count: { _all: true } }),
    ]);

    const ageBreakdown = Object.fromEntries(ageRanges.map(a => [a.ageRange || 'Unknown', a._count._all]));
    const genderBreakdown = Object.fromEntries(genders.map(g => [g.gender || 'Unknown', g._count._all]));
    const documentBreakdown = Object.fromEntries(docTypes.map(d => [d.type, d._count._all]));

    return reply.status(200).send({
      usersTotal,
      ageBreakdown,
      genderBreakdown,
      docsTotal,
      documentBreakdown,
    });
  });
}
