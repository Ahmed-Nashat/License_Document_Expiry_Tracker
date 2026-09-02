import { FastifyInstance } from 'fastify';
import { prisma } from '../lib/prisma.js';

/**
 * Utility to write append-only audit logs to the database.
 * Never throws — audit failures are logged but do not fail the request.
 */
export async function createAuditLog(
  server: FastifyInstance,
  params: {
    actorId: string;
    actorType?: 'ADMIN' | 'SYSTEM' | 'USER';
    action: string;
    targetId?: string;
    reason?: string;
    ipAddress?: string;
    requestId?: string;
    result?: 'SUCCESS' | 'FAILURE';
    metadata?: Record<string, unknown>;
  }
) {
  try {
    await prisma.auditLog.create({
      data: {
        actorId: params.actorId,
        actorType: params.actorType ?? 'ADMIN',
        action: params.action,
        targetId: params.targetId,
        reason: params.reason,
        ipAddress: params.ipAddress,
        requestId: params.requestId,
        result: params.result ?? 'SUCCESS',
        metadata: params.metadata ? (params.metadata as object) : undefined,
      },
    });
  } catch (error) {
    server.log.error({ err: error, auditParams: params }, 'Failed to write audit log');
  }
}
