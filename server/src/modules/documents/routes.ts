import { Prisma } from '@prisma/client';
import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { requireAuthenticatedSession } from '../../plugins/requireAuthenticatedSession.js';

interface JwtPayload {
  userId: string;
  sessionId: string;
}

const documentTypeEnum = z.enum([
  'NATIONAL_ID',
  'DRIVING_LICENSE',
  'PASSPORT',
  'SUBSCRIPTION',
  'OTHER',
]);

const billingCycleEnum = z.enum(['MONTHLY', 'YEARLY', 'CUSTOM']);

const createDocumentSchema = z.object({
  type: documentTypeEnum,
  title: z.string().trim().min(1).max(120),
  expiryDate: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: 'Valid date required',
  }),
  notes: z.string().trim().max(500).optional(),
  providerName: z.string().trim().max(100).optional(),
  renewalAmount: z.number().positive().optional(),
  billingCycle: billingCycleEnum.optional(),
  reminderDays: z
    .array(z.number().int().min(0).max(365))
    .optional()
    .default([90, 30, 7, 1, 0]),
});

const updateDocumentSchema = z.object({
  type: documentTypeEnum.optional(),
  title: z.string().trim().min(1).max(120).optional(),
  expiryDate: z
    .string()
    .refine((val) => !isNaN(Date.parse(val)), {
      message: 'Valid date required',
    })
    .optional(),
  notes: z.string().trim().max(500).nullable().optional(),
  providerName: z.string().trim().max(100).nullable().optional(),
  renewalAmount: z.number().positive().nullable().optional(),
  billingCycle: billingCycleEnum.nullable().optional(),
  isArchived: z.boolean().optional(),
  reminderDays: z.array(z.number().int().min(0).max(365)).optional(),
});

interface RawDocument {
  id: string;
  userId: string;
  type: string;
  title: string;
  expiryDate: Date;
  notes: string | null;
  providerName: string | null;
  renewalAmount: Prisma.Decimal | number | null;
  billingCycle: string | null;
  isArchived: boolean;
  createdAt: Date;
  updatedAt: Date;
  reminderRules?: { daysBeforeExpiry: number; enabled: boolean }[];
}

function serializeDocument(doc: RawDocument) {
  return {
    ...doc,
    expiryDate: doc.expiryDate.toISOString().split('T')[0],
    renewalAmount: doc.renewalAmount ? Number(doc.renewalAmount) : null,
    reminderRules: doc.reminderRules ?? [],
  };
}

export async function documentRoutes(app: FastifyInstance) {
  // Authentication hook for all document routes
  app.addHook('preHandler', async (request, reply) => {
    await requireAuthenticatedSession(request, reply);
  });

  // GET /api/documents - List documents with filters
  app.get('/api/documents', async (request, reply) => {
    const user = request.user as JwtPayload;
    const query = request.query as {
      type?: string;
      archived?: string;
      search?: string;
    };

    const isArchived = query.archived === 'true';
    const where: Prisma.DocumentWhereInput = {
      userId: user.userId,
      isArchived,
    };

    if (query.type && documentTypeEnum.safeParse(query.type).success) {
      where.type = query.type as z.infer<typeof documentTypeEnum>;
    }

    if (query.search && query.search.trim().length > 0) {
      where.OR = [
        { title: { contains: query.search.trim(), mode: 'insensitive' } },
        { providerName: { contains: query.search.trim(), mode: 'insensitive' } },
        { notes: { contains: query.search.trim(), mode: 'insensitive' } },
      ];
    }

    const docs = await prisma.document.findMany({
      where,
      orderBy: { expiryDate: 'asc' },
      include: {
        reminderRules: {
          select: { daysBeforeExpiry: true, enabled: true },
          orderBy: { daysBeforeExpiry: 'desc' },
        },
      },
    });

    return reply.status(200).send(docs.map(serializeDocument));
  });

  // POST /api/documents - Create document
  app.post('/api/documents', async (request, reply) => {
    const user = request.user as JwtPayload;
    const input = createDocumentSchema.parse(request.body);

    const uniqueReminderDays = Array.from(new Set(input.reminderDays));

    const doc = await prisma.document.create({
      data: {
        userId: user.userId,
        type: input.type,
        title: input.title,
        expiryDate: new Date(input.expiryDate),
        notes: input.notes,
        providerName: input.providerName,
        renewalAmount: input.renewalAmount,
        billingCycle: input.billingCycle,
        reminderRules: {
          create: uniqueReminderDays.map((days) => ({
            daysBeforeExpiry: days,
          })),
        },
      },
      include: {
        reminderRules: {
          select: { daysBeforeExpiry: true, enabled: true },
          orderBy: { daysBeforeExpiry: 'desc' },
        },
      },
    });

    return reply.status(201).send(serializeDocument(doc));
  });

  // GET /api/documents/:id - Single document details
  app.get('/api/documents/:id', async (request, reply) => {
    const user = request.user as JwtPayload;
    const { id } = request.params as { id: string };

    const doc = await prisma.document.findFirst({
      where: { id, userId: user.userId },
      include: {
        reminderRules: {
          select: { daysBeforeExpiry: true, enabled: true },
          orderBy: { daysBeforeExpiry: 'desc' },
        },
      },
    });

    if (!doc) {
      return reply
        .status(404)
        .send({ error: 'NOT_FOUND', message: 'Document not found.' });
    }

    return reply.status(200).send(serializeDocument(doc));
  });

  // PATCH /api/documents/:id - Update document
  app.patch('/api/documents/:id', async (request, reply) => {
    const user = request.user as JwtPayload;
    const { id } = request.params as { id: string };
    const input = updateDocumentSchema.parse(request.body);

    const existing = await prisma.document.findFirst({
      where: { id, userId: user.userId },
      select: { id: true },
    });

    if (!existing) {
      return reply
        .status(404)
        .send({ error: 'NOT_FOUND', message: 'Document not found.' });
    }

    const data: Prisma.DocumentUpdateInput = {};
    if (input.type !== undefined) data.type = input.type;
    if (input.title !== undefined) data.title = input.title;
    if (input.expiryDate !== undefined)
      data.expiryDate = new Date(input.expiryDate);
    if (input.notes !== undefined) data.notes = input.notes;
    if (input.providerName !== undefined)
      data.providerName = input.providerName;
    if (input.renewalAmount !== undefined)
      data.renewalAmount = input.renewalAmount;
    if (input.billingCycle !== undefined)
      data.billingCycle = input.billingCycle;
    if (input.isArchived !== undefined) data.isArchived = input.isArchived;

    if (input.reminderDays !== undefined) {
      const uniqueDays = Array.from(new Set(input.reminderDays));
      await prisma.$transaction([
        prisma.reminderRule.deleteMany({ where: { documentId: id } }),
        prisma.reminderRule.createMany({
          data: uniqueDays.map((days) => ({
            documentId: id,
            daysBeforeExpiry: days,
          })),
        }),
      ]);
    }

    const updated = await prisma.document.update({
      where: { id },
      data,
      include: {
        reminderRules: {
          select: { daysBeforeExpiry: true, enabled: true },
          orderBy: { daysBeforeExpiry: 'desc' },
        },
      },
    });

    return reply.status(200).send(serializeDocument(updated));
  });

  // DELETE /api/documents/:id - Delete document
  app.delete('/api/documents/:id', async (request, reply) => {
    const user = request.user as JwtPayload;
    const { id } = request.params as { id: string };

    const existing = await prisma.document.findFirst({
      where: { id, userId: user.userId },
      select: { id: true },
    });

    if (!existing) {
      return reply
        .status(404)
        .send({ error: 'NOT_FOUND', message: 'Document not found.' });
    }

    await prisma.document.delete({ where: { id } });
    return reply.status(204).send();
  });
}
