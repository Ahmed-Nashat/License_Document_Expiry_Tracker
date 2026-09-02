import { createHash } from 'node:crypto';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const mockPrisma = {
  $queryRaw: vi.fn().mockResolvedValue(1),
  $transaction: vi.fn().mockImplementation((operations) => Promise.all(operations)),
  user: {
    findUnique: vi.fn(),
    update: vi.fn().mockResolvedValue({}),
  },
  userSession: {
    create: vi.fn(),
    findMany: vi.fn(),
    updateMany: vi.fn().mockResolvedValue({ count: 1 }),
  },
  passwordReset: {
    upsert: vi.fn().mockResolvedValue({}),
    findUnique: vi.fn(),
    delete: vi.fn().mockResolvedValue({}),
  },
};

const sendEmail = vi.fn().mockResolvedValue({});

vi.mock('../src/lib/prisma.js', () => ({ prisma: mockPrisma }));
vi.mock('../src/utils/mailer.js', () => ({ sendEmail }));
vi.mock('../src/modules/auth/password.js', () => ({
  hashPassword: vi.fn().mockResolvedValue('new-password-hash'),
  verifyPassword: vi.fn(),
}));

describe('password reset endpoints', async () => {
  const { buildApp } = await import('../src/app.js');
  const app = buildApp();
  await app.ready();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('stores a hashed code and sends it through the mailer', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-1', email: 'person@example.com' });

    const response = await app.inject({
      method: 'POST',
      url: '/api/auth/forgot-password',
      payload: { email: 'person@example.com' },
    });

    expect(response.statusCode).toBe(200);
    expect(mockPrisma.passwordReset.upsert).toHaveBeenCalledOnce();
    expect(sendEmail).toHaveBeenCalledWith(expect.objectContaining({
      to: 'person@example.com',
      subject: 'Your DueNest password reset code',
    }));
    expect(response.json().code).toBeUndefined();
  });

  it('keeps the response generic when password reset email delivery fails', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-1', email: 'person@example.com' });
    sendEmail.mockRejectedValueOnce(new Error('SMTP unavailable'));

    const response = await app.inject({
      method: 'POST',
      url: '/api/auth/forgot-password',
      payload: { email: 'person@example.com' },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ message: 'If an account exists for this email, a reset code has been sent.' });
  });

  it('resets the password only for a valid stored code and revokes sessions', async () => {
    const email = 'person@example.com';
    const code = '123456';
    const codeHash = createHash('sha256')
      .update(`${process.env.JWT_REFRESH_SECRET}:password-reset:${email}:${code}`)
      .digest('base64url');
    mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-1', email });
    mockPrisma.passwordReset.findUnique.mockResolvedValue({
      userId: 'user-1',
      codeHash,
      expiresAt: new Date(Date.now() + 60_000),
    });

    const response = await app.inject({
      method: 'POST',
      url: '/api/auth/reset-password',
      payload: { email, code, newPassword: 'a-new-secure-password' },
    });

    expect(response.statusCode).toBe(200);
    expect(mockPrisma.userSession.updateMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', revokedAt: null },
      data: { revokedAt: expect.any(Date) },
    });
    expect(mockPrisma.passwordReset.delete).toHaveBeenCalledWith({ where: { userId: 'user-1' } });
  });
});
