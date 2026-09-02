import { describe, expect, it, vi, beforeEach } from 'vitest';

const mockPrisma = {
  $queryRaw: vi.fn().mockResolvedValue(1),
  document: {
    findMany: vi.fn(),
    create: vi.fn(),
    findFirst: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  },
  reminderRule: {
    deleteMany: vi.fn(),
    createMany: vi.fn(),
  },
  userSession: {
    findUnique: vi.fn().mockResolvedValue({
      userId: 'user-123',
      revokedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
      user: { suspendedAt: null },
    }),
  },
  $transaction: vi.fn().mockImplementation((promises) => Promise.all(promises)),
};

vi.mock('../src/lib/prisma.js', () => ({ prisma: mockPrisma }));

describe('document endpoints', async () => {
  const { buildApp } = await import('../src/app.js');
  const app = buildApp();
  await app.ready();

  const token = app.jwt.sign({ userId: 'user-123', sessionId: 'sess-1' });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('rejects unauthenticated requests with 401', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/documents',
    });
    expect(response.statusCode).toBe(401);
  });

  it('rejects a token whose server session was revoked', async () => {
    mockPrisma.userSession.findUnique.mockResolvedValueOnce({
      userId: 'user-123',
      revokedAt: new Date(),
      expiresAt: new Date(Date.now() + 60_000),
      user: { suspendedAt: null },
    });

    const response = await app.inject({
      method: 'GET',
      url: '/api/documents',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(response.statusCode).toBe(401);
  });

  it('creates a new document with default reminder rules', async () => {
    const mockDoc = {
      id: 'doc-1',
      userId: 'user-123',
      type: 'NATIONAL_ID',
      title: 'National Identity Card',
      expiryDate: new Date('2028-05-15'),
      notes: null,
      providerName: null,
      renewalAmount: null,
      billingCycle: null,
      isArchived: false,
      createdAt: new Date(),
      updatedAt: new Date(),
      reminderRules: [
        { daysBeforeExpiry: 90, enabled: true },
        { daysBeforeExpiry: 30, enabled: true },
        { daysBeforeExpiry: 7, enabled: true },
        { daysBeforeExpiry: 1, enabled: true },
        { daysBeforeExpiry: 0, enabled: true },
      ],
    };

    mockPrisma.document.create.mockResolvedValue(mockDoc);

    const response = await app.inject({
      method: 'POST',
      url: '/api/documents',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        type: 'NATIONAL_ID',
        title: 'National Identity Card',
        expiryDate: '2028-05-15',
      },
    });

    expect(response.statusCode).toBe(201);
    const body = response.json();
    expect(body.title).toBe('National Identity Card');
    expect(body.expiryDate).toBe('2028-05-15');
    expect(body.reminderRules).toHaveLength(5);
  });

  it('lists active documents for the user', async () => {
    mockPrisma.document.findMany.mockResolvedValue([
      {
        id: 'doc-1',
        userId: 'user-123',
        type: 'DRIVING_LICENSE',
        title: 'Driver License',
        expiryDate: new Date('2027-10-20'),
        notes: null,
        providerName: null,
        renewalAmount: null,
        billingCycle: null,
        isArchived: false,
        createdAt: new Date(),
        updatedAt: new Date(),
        reminderRules: [],
      },
    ]);

    const response = await app.inject({
      method: 'GET',
      url: '/api/documents',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(Array.isArray(body)).toBe(true);
    expect(body[0].title).toBe('Driver License');
  });

  it('updates an existing document', async () => {
    mockPrisma.document.findFirst.mockResolvedValue({ id: 'doc-1' });
    mockPrisma.document.update.mockResolvedValue({
      id: 'doc-1',
      userId: 'user-123',
      type: 'DRIVING_LICENSE',
      title: 'Updated Driver License',
      expiryDate: new Date('2029-01-01'),
      notes: 'Renewed',
      providerName: null,
      renewalAmount: null,
      billingCycle: null,
      isArchived: false,
      createdAt: new Date(),
      updatedAt: new Date(),
      reminderRules: [],
    });

    const response = await app.inject({
      method: 'PATCH',
      url: '/api/documents/doc-1',
      headers: { authorization: `Bearer ${token}` },
      payload: { title: 'Updated Driver License', notes: 'Renewed' },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().title).toBe('Updated Driver License');
  });

  it('deletes a document', async () => {
    mockPrisma.document.findFirst.mockResolvedValue({ id: 'doc-1' });
    mockPrisma.document.delete.mockResolvedValue({ id: 'doc-1' });

    const response = await app.inject({
      method: 'DELETE',
      url: '/api/documents/doc-1',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(response.statusCode).toBe(204);
  });
});
