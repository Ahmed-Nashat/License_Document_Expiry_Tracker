import { FastifyInstance } from 'fastify';

/**
 * Utility to write append-only audit logs to the database.
 */
export async function createAuditLog(
  server: FastifyInstance,
  params: {
    actorId: string;
    action: string;
    targetId?: string;
    reason?: string;
    ipAddress?: string;
  }
) {
  try {
    await server.prisma.auditLog.create({
      data: {
        actorId: params.actorId,
        action: params.action,
        targetId: params.targetId,
        reason: params.reason,
        ipAddress: params.ipAddress,
      },
    });
  } catch (error) {
    // We log the error but don't crash the request if audit logging fails,
    // though in a high-security environment you might want to fail closed.
    server.log.error({ err: error, auditParams: params }, 'Failed to write audit log');
  }
}
