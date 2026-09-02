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
    findUnique: vi.fn(),
    updateMany: vi.fn().mockResolvedValue({ count: 1 }),
  },
  passwordReset: {
    upsert: vi.fn().mockResolvedValue({}),
    findUnique: vi.fn(),
    update: vi.fn().mockResolvedValue({}),
    delete: vi.fn().mockResolvedValue({}),
  },
};

const sendEmail = vi.fn().mockResolvedValue({});
const verifyPassword = vi.fn();

vi.mock('../src/lib/prisma.js', () => ({ prisma: mockPrisma }));
vi.mock('../src/utils/mailer.js', () => ({ sendEmail }));
vi.mock('../src/modules/auth/password.js', () => ({
  hashPassword: vi.fn().mockResolvedValue('new-password-hash'),
  verifyPassword,
}));

describe('password reset endpoints', async () => {
  const { buildApp } = await import('../src/app.js');
  const app = buildApp();
  await app.ready();

  beforeEach(() => {
    vi.clearAllMocks();
    mockPrisma.userSession.findUnique.mockResolvedValue({
      userId: 'user-1',
      revokedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
      user: { suspendedAt: null },
    });
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

  it('does not create a new session for a suspended account', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      email: 'person@example.com',
      passwordHash: 'password-hash',
      role: 'USER',
      suspendedAt: new Date(),
    });
    verifyPassword.mockResolvedValueOnce(true);

    const response = await app.inject({
      method: 'POST',
      url: '/api/auth/login',
      payload: { email: 'person@example.com', password: 'a-secure-password' },
    });

    expect(response.statusCode).toBe(403);
    expect(mockPrisma.userSession.create).not.toHaveBeenCalled();
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
      attemptCount: 0,
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

  it('rejects a revoked session before it can update the profile', async () => {
    const token = app.jwt.sign({ userId: 'user-1', sessionId: 'session-1', role: 'USER' });
    mockPrisma.userSession.findUnique.mockResolvedValueOnce({
      userId: 'user-1',
      revokedAt: new Date(),
      expiresAt: new Date(Date.now() + 60_000),
      user: { suspendedAt: null },
    });

    const response = await app.inject({
      method: 'PATCH',
      url: '/api/auth/profile',
      headers: { authorization: `Bearer ${token}` },
      payload: { displayName: 'Updated User' },
    });

    expect(response.statusCode).toBe(401);
    expect(mockPrisma.user.update).not.toHaveBeenCalled();
  });

  it('rejects demographic values outside the profile enum contract', async () => {
    const token = app.jwt.sign({ userId: 'user-1', sessionId: 'session-1', role: 'USER' });

    const response = await app.inject({
      method: 'PATCH',
      url: '/api/auth/profile',
      headers: { authorization: `Bearer ${token}` },
      payload: { displayName: 'Updated User', ageRange: '18-24', gender: 'Male' },
    });

    expect(response.statusCode).toBe(400);
    expect(mockPrisma.user.update).not.toHaveBeenCalled();
  });

  it('updates a password for an active session and revokes all sessions', async () => {
    const token = app.jwt.sign({ userId: 'user-1', sessionId: 'session-1', role: 'USER' });
    mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-1', passwordHash: 'password-hash' });
    verifyPassword.mockResolvedValueOnce(true);

    const response = await app.inject({
      method: 'PATCH',
      url: '/api/auth/password',
      headers: { authorization: `Bearer ${token}` },
      payload: { currentPassword: 'a-secure-password', newPassword: 'a-new-secure-password' },
    });

    expect(response.statusCode).toBe(200);
    expect(verifyPassword).toHaveBeenCalledWith('a-secure-password', 'password-hash');
    expect(mockPrisma.userSession.updateMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', revokedAt: null },
      data: { revokedAt: expect.any(Date) },
    });
  });

  it('counts invalid reset-code attempts without disclosing whether the account exists', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-1', email: 'person@example.com' });
    mockPrisma.passwordReset.findUnique.mockResolvedValue({
      userId: 'user-1',
      codeHash: 'wrong-hash',
      attemptCount: 0,
      expiresAt: new Date(Date.now() + 60_000),
    });

    const response = await app.inject({
      method: 'POST',
      url: '/api/auth/reset-password',
      payload: { email: 'person@example.com', code: '123456', newPassword: 'a-new-secure-password' },
    });

    expect(response.statusCode).toBe(400);
    expect(mockPrisma.passwordReset.update).toHaveBeenCalledWith({
      where: { userId: 'user-1' },
      data: { attemptCount: { increment: 1 } },
    });
  });
});
