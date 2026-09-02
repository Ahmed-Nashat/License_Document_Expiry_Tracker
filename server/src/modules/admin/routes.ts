import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { requireAdmin } from '../../plugins/requireAdmin.js';
import { createAuditLog } from '../../utils/auditLogger.js';

interface JwtPayload {
  userId: string;
  sessionId: string;
  role: string;
}

const ADMIN_USER_SELECT = {
  id: true,
  email: true,
  displayName: true,
  role: true,
  ageRange: true,
  gender: true,
  timeZone: true,
  emailNotificationsEnabled: true,
  suspendedAt: true,
  suspendedReason: true,
  suspendedById: true,
  createdAt: true,
  updatedAt: true,
  _count: {
    select: {
      documents: true,
      sessions: { where: { revokedAt: null, expiresAt: { gt: new Date() } } },
    },
  },
} as const;

export async function adminRoutes(app: FastifyInstance) {
  app.addHook('preHandler', async (request, reply) => {
    await requireAdmin(request, reply);
  });

  // â”€â”€â”€ User Management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // GET /api/admin/users - Paginated user list with search and filters
  app.get('/api/admin/users', async (request, reply) => {
    const q = request.query as { search?: string; page?: string; limit?: string; suspended?: string };
    const page = Math.max(1, parseInt(q.page ?? '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(q.limit ?? '50', 10)));
    const skip = (page - 1) * limit;

    const baseWhere: Record<string, unknown> = {};
    if (q.search) {
      baseWhere.OR = [
        { email: { contains: q.search.trim(), mode: 'insensitive' } },
        { displayName: { contains: q.search.trim(), mode: 'insensitive' } },
      ];
    }
    if (q.suspended === 'true') baseWhere.suspendedAt = { not: null };
    if (q.suspended === 'false') baseWhere.suspendedAt = null;

    const [users, total] = await Promise.all([
      prisma.user.findMany({ where: baseWhere, orderBy: { createdAt: 'desc' }, take: limit, skip, select: ADMIN_USER_SELECT }),
      prisma.user.count({ where: baseWhere }),
    ]);

    return reply.status(200).send({ users, total, page, limit, pages: Math.ceil(total / limit) });
  });

  // GET /api/admin/users/:id - Single user detail
  app.get('/api/admin/users/:id', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const { id } = request.params as { id: string };

    const user = await prisma.user.findUnique({ where: { id }, select: ADMIN_USER_SELECT });
    if (!user) return reply.status(404).send({ error: 'NOT_FOUND', message: 'User not found.' });

    await createAuditLog(app, {
      actorId: admin.userId,
      action: 'VIEW_USER_METADATA',
      targetId: id,
      ipAddress: request.ip,
      requestId: request.id,
    });

    return reply.status(200).send(user);
  });

  // POST /api/admin/users/:id/sessions/revoke - Force sign out
  app.post('/api/admin/users/:id/sessions/revoke', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const { id: targetUserId } = request.params as { id: string };

    const targetUser = await prisma.user.findUnique({ where: { id: targetUserId }, select: { id: true } });
    if (!targetUser) return reply.status(404).send({ error: 'NOT_FOUND', message: 'User not found.' });

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
      requestId: request.id,
    });

    return reply.status(200).send({ message: 'All active sessions revoked.' });
  });

  // POST /api/admin/users/:id/suspend - Suspend a user account
  app.post('/api/admin/users/:id/suspend', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const { id: targetUserId } = request.params as { id: string };
    const { reason } = z.object({ reason: z.string().min(5).max(500) }).parse(request.body);

    const user = await prisma.user.findUnique({ where: { id: targetUserId }, select: { id: true, role: true } });
    if (!user) return reply.status(404).send({ error: 'NOT_FOUND', message: 'User not found.' });
    if (user.role === 'ADMIN') return reply.status(403).send({ error: 'FORBIDDEN', message: 'Cannot suspend another admin.' });

    await prisma.$transaction([
      prisma.user.update({
        where: { id: targetUserId },
        data: { suspendedAt: new Date(), suspendedReason: reason, suspendedById: admin.userId },
      }),
      // Force sign out all sessions
      prisma.userSession.updateMany({
        where: { userId: targetUserId, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);

    await createAuditLog(app, {
      actorId: admin.userId,
      action: 'USER_SUSPENDED',
      targetId: targetUserId,
      reason,
      ipAddress: request.ip,
      requestId: request.id,
    });

    return reply.status(200).send({ message: 'User suspended and sessions revoked.' });
  });

  // POST /api/admin/users/:id/reactivate - Lift a suspension
  app.post('/api/admin/users/:id/reactivate', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const { id: targetUserId } = request.params as { id: string };

    const user = await prisma.user.findUnique({ where: { id: targetUserId }, select: { id: true, suspendedAt: true } });
    if (!user) return reply.status(404).send({ error: 'NOT_FOUND', message: 'User not found.' });
    if (!user.suspendedAt) return reply.status(400).send({ error: 'NOT_SUSPENDED', message: 'User is not suspended.' });

    await prisma.user.update({
      where: { id: targetUserId },
      data: { suspendedAt: null, suspendedReason: null, suspendedById: null },
    });

    await createAuditLog(app, {
      actorId: admin.userId,
      action: 'USER_REACTIVATED',
      targetId: targetUserId,
      ipAddress: request.ip,
      requestId: request.id,
    });

    return reply.status(200).send({ message: 'User reactivated.' });
  });

  // POST /api/admin/users/:id/delete-workflow - Open a deletion support ticket
  app.post('/api/admin/users/:id/delete-workflow', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const { id: targetUserId } = request.params as { id: string };

    const user = await prisma.user.findUnique({ where: { id: targetUserId }, select: { id: true, email: true } });
    if (!user) return reply.status(404).send({ error: 'NOT_FOUND', message: 'User not found.' });

    const ticket = await prisma.supportTicket.create({
      data: {
        requesterEmail: user.email,
        userId: targetUserId,
        category: 'PRIVACY_DELETION',
        subject: `Account deletion request for ${user.email}`,
        description: `Admin-initiated deletion workflow for user ${user.email} (${targetUserId}).`,
        status: 'OPEN',
        assignedToId: admin.userId,
      },
    });

    await createAuditLog(app, {
      actorId: admin.userId,
      action: 'DELETION_WORKFLOW_STARTED',
      targetId: targetUserId,
      ipAddress: request.ip,
      requestId: request.id,
      metadata: { ticketId: ticket.id },
    });

    return reply.status(201).send({ ticketId: ticket.id });
  });

  // â”€â”€â”€ Audit Logs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // GET /api/admin/audit-logs - Paginated, filtered audit log
  app.get('/api/admin/audit-logs', async (request, reply) => {
    const q = request.query as { page?: string; limit?: string; action?: string; actorId?: string; targetId?: string; result?: string; from?: string; to?: string };
    const page = Math.max(1, parseInt(q.page ?? '1', 10));
    const limit = Math.min(200, Math.max(1, parseInt(q.limit ?? '100', 10)));
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = {};
    if (q.action) where.action = { contains: q.action.trim(), mode: 'insensitive' };
    if (q.actorId) where.actorId = q.actorId.trim();
    if (q.targetId) where.targetId = q.targetId.trim();
    if (q.result) where.result = q.result.trim().toUpperCase();
    if (q.from || q.to) {
      where.timestamp = {
        ...(q.from ? { gte: new Date(q.from) } : {}),
        ...(q.to ? { lte: new Date(q.to) } : {}),
      };
    }

    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({ where, orderBy: { timestamp: 'desc' }, take: limit, skip }),
      prisma.auditLog.count({ where }),
    ]);

    return reply.status(200).send({ logs, total, page, limit, pages: Math.ceil(total / limit) });
  });

  // â”€â”€â”€ Analytics / Metrics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // GET /api/admin/metrics - Extended analytics
  app.get('/api/admin/metrics', async (request, reply) => {
    const sevenDaysAgo = new Date(Date.now() - 7 * 86_400_000);
    const now = new Date();
    const soonCutoff = new Date(Date.now() + 30 * 86_400_000);
    const criticalCutoff = new Date(Date.now() + 7 * 86_400_000);

    const [
      usersTotal,
      newUsers7d,
      ageRanges,
      genders,
      docsTotal,
      docTypes,
      expiredDocs,
      criticalDocs,
      soonDocs,
      notifTotal,
      notifSent,
      notifFailed,
      notifPending,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { createdAt: { gte: sevenDaysAgo } } }),
      prisma.user.groupBy({ by: ['ageRange'], _count: { _all: true } }),
      prisma.user.groupBy({ by: ['gender'], _count: { _all: true } }),
      prisma.document.count({ where: { isArchived: false } }),
      prisma.document.groupBy({ by: ['type'], where: { isArchived: false }, _count: { _all: true } }),
      prisma.document.count({ where: { isArchived: false, expiryDate: { lt: now } } }),
      prisma.document.count({ where: { isArchived: false, expiryDate: { gte: now, lte: criticalCutoff } } }),
      prisma.document.count({ where: { isArchived: false, expiryDate: { gt: criticalCutoff, lte: soonCutoff } } }),
      prisma.notificationLog.count(),
      prisma.notificationLog.count({ where: { status: 'SENT' } }),
      prisma.notificationLog.count({ where: { status: 'FAILED' } }),
      prisma.notificationLog.count({ where: { status: 'PENDING' } }),
    ]);

    return reply.status(200).send({
      users: { total: usersTotal, newLast7Days: newUsers7d },
      documents: {
        total: docsTotal,
        expired: expiredDocs,
        critical: criticalDocs,
        soon: soonDocs,
        byType: Object.fromEntries(docTypes.map(d => [d.type, d._count._all])),
      },
      reminders: {
        total: notifTotal,
        sent: notifSent,
        failed: notifFailed,
        pending: notifPending,
        deliveryRate: notifTotal > 0 ? Math.round((notifSent / notifTotal) * 100) : 0,
      },
      demographics: {
        byAge: Object.fromEntries(ageRanges.map(a => [a.ageRange ?? 'Unknown', a._count._all])),
        byGender: Object.fromEntries(genders.map(g => [g.gender ?? 'Unknown', g._count._all])),
      },
    });
  });

  // â”€â”€â”€ Reminder Operations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // GET /api/admin/reminders/stats
  app.get('/api/admin/reminders/stats', async (request, reply) => {
    const [pending, processing, sent, failed, pauseConfig] = await Promise.all([
      prisma.notificationLog.count({ where: { status: 'PENDING' } }),
      prisma.notificationLog.count({ where: { status: 'PROCESSING' } }),
      prisma.notificationLog.count({ where: { status: 'SENT' } }),
      prisma.notificationLog.count({ where: { status: 'FAILED' } }),
      prisma.systemConfig.findUnique({ where: { key: 'REMINDER_ENGINE_PAUSED' } }),
    ]);

    const lastEngineRun = await prisma.systemConfig.findUnique({ where: { key: 'REMINDER_ENGINE_LAST_RUN' } });

    return reply.status(200).send({
      queue: { pending, processing, sent, failed },
      paused: pauseConfig?.value === 'true',
      lastRun: lastEngineRun?.value ?? null,
    });
  });

  // GET /api/admin/reminders/logs - Paginated notification log
  app.get('/api/admin/reminders/logs', async (request, reply) => {
    const q = request.query as { page?: string; limit?: string; status?: string; userId?: string };
    const page = Math.max(1, parseInt(q.page ?? '1', 10));
    const limit = Math.min(100, parseInt(q.limit ?? '50', 10));
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = {};
    if (q.status) where.status = q.status.toUpperCase();
    if (q.userId) where.userId = q.userId;

    const [logs, total] = await Promise.all([
      prisma.notificationLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip,
        include: { document: { select: { title: true, type: true } }, user: { select: { email: true } } },
      }),
      prisma.notificationLog.count({ where }),
    ]);

    return reply.status(200).send({ logs, total, page, limit, pages: Math.ceil(total / limit) });
  });

  // POST /api/admin/reminders/retry/:logId
  app.post('/api/admin/reminders/retry/:logId', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const { logId } = request.params as { logId: string };

    const log = await prisma.notificationLog.findUnique({ where: { id: logId } });
    if (!log) return reply.status(404).send({ error: 'NOT_FOUND', message: 'Notification log not found.' });
    if (log.status !== 'FAILED') return reply.status(400).send({ error: 'NOT_FAILED', message: 'Only FAILED reminders can be retried.' });

    await prisma.notificationLog.update({
      where: { id: logId },
      data: { status: 'PENDING', processingAt: null, error: null, retryCount: 0 },
    });

    await createAuditLog(app, {
      actorId: admin.userId,
      action: 'REMINDER_RETRY',
      targetId: logId,
      ipAddress: request.ip,
      requestId: request.id,
    });

    return reply.status(200).send({ message: 'Reminder re-queued for delivery.' });
  });

  // POST /api/admin/reminders/pause
  app.post('/api/admin/reminders/pause', async (request, reply) => {
    const admin = request.user as JwtPayload;

    await prisma.systemConfig.upsert({
      where: { key: 'REMINDER_ENGINE_PAUSED' },
      update: { value: 'true', updatedById: admin.userId, reason: 'Admin paused reminder delivery' },
      create: { key: 'REMINDER_ENGINE_PAUSED', value: 'true', updatedById: admin.userId, reason: 'Admin paused reminder delivery' },
    });

    await createAuditLog(app, { actorId: admin.userId, action: 'REMINDER_ENGINE_PAUSED', ipAddress: request.ip, requestId: request.id });
    return reply.status(200).send({ message: 'Reminder engine paused.' });
  });

  // POST /api/admin/reminders/resume
  app.post('/api/admin/reminders/resume', async (request, reply) => {
    const admin = request.user as JwtPayload;

    await prisma.systemConfig.upsert({
      where: { key: 'REMINDER_ENGINE_PAUSED' },
      update: { value: 'false', updatedById: admin.userId, reason: 'Admin resumed reminder delivery' },
      create: { key: 'REMINDER_ENGINE_PAUSED', value: 'false', updatedById: admin.userId, reason: 'Admin resumed reminder delivery' },
    });

    await createAuditLog(app, { actorId: admin.userId, action: 'REMINDER_ENGINE_RESUMED', ipAddress: request.ip, requestId: request.id });
    return reply.status(200).send({ message: 'Reminder engine resumed.' });
  });

  // â”€â”€â”€ Security Center â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // GET /api/admin/security/sessions - Active admin sessions
  app.get('/api/admin/security/sessions', async (request, reply) => {
    const sessions = await prisma.userSession.findMany({
      where: {
        revokedAt: null,
        expiresAt: { gt: new Date() },
        user: { role: 'ADMIN' },
      },
      orderBy: { lastUsedAt: 'desc' },
      select: {
        id: true,
        userId: true,
        deviceName: true,
        deviceType: true,
        lastUsedAt: true,
        expiresAt: true,
        user: { select: { email: true, displayName: true } },
      },
    });

    return reply.status(200).send(sessions);
  });

  // GET /api/admin/security/events - Recent security events from audit log
  app.get('/api/admin/security/events', async (request, reply) => {
    const SECURITY_ACTIONS = [
      'REVOKE_ALL_SESSIONS', 'USER_SUSPENDED', 'USER_REACTIVATED',
      'DELETION_WORKFLOW_STARTED', 'REMINDER_ENGINE_PAUSED', 'REMINDER_ENGINE_RESUMED',
      'ROLE_CHANGE', 'SYSTEM_CONFIG_UPDATED', 'ADMIN_LOGIN_FAILED', 'VIEW_USER_METADATA',
    ];

    const events = await prisma.auditLog.findMany({
      where: { action: { in: SECURITY_ACTIONS } },
      orderBy: { timestamp: 'desc' },
      take: 100,
    });

    return reply.status(200).send(events);
  });

  // â”€â”€â”€ Support Inbox â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // GET /api/admin/support - Paginated ticket list
  app.get('/api/admin/support', async (request, reply) => {
    const q = request.query as { page?: string; limit?: string; status?: string; category?: string };
    const page = Math.max(1, parseInt(q.page ?? '1', 10));
    const limit = Math.min(100, parseInt(q.limit ?? '50', 10));
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = {};
    if (q.status) where.status = q.status.toUpperCase();
    if (q.category) where.category = q.category.toUpperCase();

    const [tickets, total] = await Promise.all([
      prisma.supportTicket.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip,
        include: {
          assignee: { select: { email: true, displayName: true } },
        },
      }),
      prisma.supportTicket.count({ where }),
    ]);

    return reply.status(200).send({ tickets, total, page, limit, pages: Math.ceil(total / limit) });
  });

  // POST /api/admin/support - Create a ticket (admin or consumer via their JWT)
  app.post('/api/admin/support', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const input = z.object({
      requesterEmail: z.string().email(),
      userId: z.string().optional(),
      category: z.enum(['ACCOUNT_ACCESS', 'REMINDER_DELIVERY', 'PRIVACY_DELETION', 'OTHER']),
      subject: z.string().min(5).max(200),
      description: z.string().min(10).max(5000),
    }).parse(request.body);

    const ticket = await prisma.supportTicket.create({
      data: { ...input, assignedToId: admin.userId },
    });

    await createAuditLog(app, {
      actorId: admin.userId,
      action: 'SUPPORT_TICKET_CREATED',
      targetId: ticket.id,
      ipAddress: request.ip,
      requestId: request.id,
    });

    return reply.status(201).send(ticket);
  });

  // PATCH /api/admin/support/:id - Update a ticket
  app.patch('/api/admin/support/:id', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const { id } = request.params as { id: string };
    const input = z.object({
      status: z.enum(['OPEN', 'IN_PROGRESS', 'RESOLVED']).optional(),
      assignedToId: z.string().optional(),
      internalNotes: z.string().max(5000).optional(),
    }).parse(request.body);

    const ticket = await prisma.supportTicket.findUnique({ where: { id } });
    if (!ticket) return reply.status(404).send({ error: 'NOT_FOUND', message: 'Ticket not found.' });

    const updated = await prisma.supportTicket.update({ where: { id }, data: input });

    await createAuditLog(app, {
      actorId: admin.userId,
      action: 'SUPPORT_TICKET_UPDATED',
      targetId: id,
      ipAddress: request.ip,
      requestId: request.id,
      metadata: { changes: input },
    });

    return reply.status(200).send(updated);
  });

  // â”€â”€â”€ System Configuration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // GET /api/admin/config
  app.get('/api/admin/config', async (request, reply) => {
    const configs = await prisma.systemConfig.findMany({ orderBy: { key: 'asc' } });
    return reply.status(200).send(configs);
  });

  // PUT /api/admin/config/:key
  app.put('/api/admin/config/:key', async (request, reply) => {
    const admin = request.user as JwtPayload;
    const { key } = request.params as { key: string };
    const { value, reason } = z.object({
      value: z.string().min(1).max(1000),
      reason: z.string().min(5).max(500),
    }).parse(request.body);

    const config = await prisma.systemConfig.upsert({
      where: { key },
      update: { value, updatedById: admin.userId, reason },
      create: { key, value, updatedById: admin.userId, reason },
    });

    await createAuditLog(app, {
      actorId: admin.userId,
      action: 'SYSTEM_CONFIG_UPDATED',
      targetId: key,
      reason,
      ipAddress: request.ip,
      requestId: request.id,
      metadata: { key, newValue: value },
    });

    return reply.status(200).send(config);
  });
  app.post('/api/admin/support/:id/message', async (request, reply) => {
    const params = z.object({ id: z.string().cuid() }).parse(request.params);
    const input = z.object({ message: z.string().min(1) }).parse(request.body);

    const ticket = await prisma.supportTicket.findUnique({ where: { id: params.id } });
    if (!ticket) return reply.status(404).send({ error: 'NOT_FOUND', message: 'Ticket not found.' });

    // Send email to requester
    const { sendEmail } = await import('../../utils/mailer.js');
    try {
      await sendEmail({
        to: ticket.requesterEmail,
        subject: `Update on your DueNest Support Ticket: ${ticket.subject}`,
        html: `<p>An admin has sent you a message regarding your ticket:</p><blockquote>${input.message.replace(/\n/g, '<br>')}</blockquote>`,
      });
    } catch (err) {
      request.log.error({ err }, 'Failed to send support email message');
      return reply.status(500).send({ error: 'EMAIL_FAILED', message: 'Could not send the email.' });
    }
    await createAuditLog(request.server, { 
      actorId: (request.user as any).userId, 
      action: 'SUPPORT_MESSAGE_SENT', 
      actorType: 'ADMIN', 
      targetId: ticket.id, 
      result: 'SUCCESS' 
    });
    return reply.status(200).send({ message: 'Message sent successfully.' });
  });
}
