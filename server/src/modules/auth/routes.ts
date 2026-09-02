import { createHash, randomBytes, randomInt, timingSafeEqual } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { env } from '../../config/env.js';
import { prisma } from '../../lib/prisma.js';
import { sendEmail } from '../../utils/mailer.js';
import { requireAuthenticatedSession } from '../../plugins/requireAuthenticatedSession.js';
import { hashPassword, verifyPassword } from './password.js';

interface JwtPayload {
  userId: string;
  sessionId: string;
  role: string;
}

const credentials = z.object({
  email: z.string().trim().email().max(254).transform((value) => value.toLowerCase()),
  password: z.string().min(12).max(128),
  displayName: z.string().trim().min(1).max(80).optional(),
});
const registration = credentials.extend({
  ageRange: z.enum(['UNDER_18', 'AGE_18_24', 'AGE_25_34', 'AGE_35_44', 'AGE_45_PLUS']),
  gender: z.enum(['MALE', 'FEMALE', 'PREFER_NOT_TO_SAY']).optional(),
});

const cookieName = 'deunest_refresh';
const cookieOptions = { httpOnly: true, secure: env.COOKIE_SECURE, sameSite: env.COOKIE_SAME_SITE, path: '/api/auth', domain: env.COOKIE_DOMAIN || undefined };
const refreshHash = (value: string) => createHash('sha256').update(`${env.JWT_REFRESH_SECRET}:${value}`).digest('base64url');
const refreshToken = () => randomBytes(48).toString('base64url');
const expiry = () => new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 86_400_000);
const passwordResetCode = () => randomInt(0, 1_000_000).toString().padStart(6, '0');
const passwordResetHash = (email: string, code: string) => createHash('sha256').update(`${env.JWT_REFRESH_SECRET}:password-reset:${email}:${code}`).digest('base64url');
const passwordResetExpiry = () => new Date(Date.now() + 15 * 60_000);
const hashesMatch = (left: string, right: string) => {
  const leftValue = Buffer.from(left);
  const rightValue = Buffer.from(right);
  return leftValue.length === rightValue.length && timingSafeEqual(leftValue, rightValue);
};
const hasAllowedCookieOrigin = (origin: string | undefined) =>
  env.NODE_ENV === 'test' || Boolean(origin && env.webOrigins.includes(origin));
const publicUser = (user: { id: string; email: string; displayName: string | null; role: string; ageRange: string | null; gender: string | null }) => ({ id: user.id, email: user.email, displayName: user.displayName, role: user.role, ageRange: user.ageRange, gender: user.gender });

async function createSession(app: FastifyInstance, userId: string, deviceName?: string) {
  const rawToken = refreshToken();
  const session = await prisma.userSession.create({ data: { userId, refreshTokenHash: refreshHash(rawToken), deviceName: deviceName?.slice(0, 160), deviceType: 'web', expiresAt: expiry() } });
  const oldSessions = await prisma.userSession.findMany({ where: { userId, revokedAt: null, expiresAt: { gt: new Date() } }, orderBy: { lastUsedAt: 'desc' }, skip: 2, select: { id: true } });
  if (oldSessions.length) await prisma.userSession.updateMany({ where: { id: { in: oldSessions.map((sessionItem) => sessionItem.id) } }, data: { revokedAt: new Date() } });
  return { rawToken, session };
}

export async function authRoutes(app: FastifyInstance) {
  const issue = (userId: string, role: string, sessionId: string) => app.jwt.sign({ userId, role, sessionId }, { expiresIn: `${env.ACCESS_TOKEN_TTL_MINUTES}m` });
  
  app.post('/api/auth/register', {
    config: {
      rateLimit: {
        max: 5,
        timeWindow: '1 minute'
      }
    }
  }, async (request, reply) => {
    const input = registration.parse(request.body);
    if (await prisma.user.findUnique({ where: { email: input.email }, select: { id: true } })) return reply.status(409).send({ error: 'EMAIL_IN_USE', message: 'An account already exists for this email.' });
    const user = await prisma.user.create({ data: { email: input.email, passwordHash: await hashPassword(input.password), displayName: input.displayName, ageRange: input.ageRange, gender: input.gender } });
    const { rawToken, session } = await createSession(app, user.id, request.headers['user-agent']);
    reply.setCookie(cookieName, rawToken, { ...cookieOptions, expires: session.expiresAt });
    return reply.status(201).send({ accessToken: issue(user.id, user.role, session.id), user: publicUser(user) });
  });

  app.post('/api/auth/login', {
    config: {
      rateLimit: {
        max: 5,
        timeWindow: '1 minute'
      }
    }
  }, async (request, reply) => {
    const input = credentials.pick({ email: true, password: true }).parse(request.body);
    const user = await prisma.user.findUnique({ where: { email: input.email } });
    if (!user || !(await verifyPassword(input.password, user.passwordHash))) return reply.status(401).send({ error: 'INVALID_CREDENTIALS', message: 'Email or password is incorrect.' });
    if (user.suspendedAt) return reply.status(403).send({ error: 'ACCOUNT_SUSPENDED', message: 'This account has been suspended.' });
    const { rawToken, session } = await createSession(app, user.id, request.headers['user-agent']);
    reply.setCookie(cookieName, rawToken, { ...cookieOptions, expires: session.expiresAt });
    return { accessToken: issue(user.id, user.role, session.id), user: publicUser(user) };
  });

  app.post('/api/auth/refresh', async (request, reply) => {
    if (!hasAllowedCookieOrigin(request.headers.origin)) {
      return reply.status(403).send({ error: 'FORBIDDEN_ORIGIN', message: 'Request origin is not allowed.' });
    }
    const rawToken = request.cookies[cookieName];
    if (!rawToken) return reply.status(401).send({ error: 'SESSION_EXPIRED', message: 'Please sign in again.' });
    const session = await prisma.userSession.findUnique({
      where: { refreshTokenHash: refreshHash(rawToken) },
      include: { user: { select: { id: true, email: true, displayName: true, role: true, ageRange: true, gender: true, suspendedAt: true } } },
    });
    if (!session || session.revokedAt || session.expiresAt <= new Date() || session.user.suspendedAt) {
      return reply.status(401).send({ error: 'SESSION_EXPIRED', message: 'Please sign in again.' });
    }
    const nextToken = refreshToken();
    const expiresAt = expiry();
    await prisma.userSession.update({ where: { id: session.id }, data: { refreshTokenHash: refreshHash(nextToken), lastUsedAt: new Date(), lastRefreshAt: new Date(), expiresAt } });
    reply.setCookie(cookieName, nextToken, { ...cookieOptions, expires: expiresAt });
    return { accessToken: issue(session.userId, session.user.role, session.id), user: publicUser(session.user) };
  });
  app.post('/api/auth/logout', async (request, reply) => {
    if (!hasAllowedCookieOrigin(request.headers.origin)) {
      return reply.status(403).send({ error: 'FORBIDDEN_ORIGIN', message: 'Request origin is not allowed.' });
    }
    const rawToken = request.cookies[cookieName];
    if (rawToken) await prisma.userSession.updateMany({ where: { refreshTokenHash: refreshHash(rawToken), revokedAt: null }, data: { revokedAt: new Date() } });
    reply.clearCookie(cookieName, cookieOptions);
    return reply.status(204).send();
  });
  app.post('/api/auth/forgot-password', {
    config: {
      rateLimit: { max: 3, timeWindow: '1 hour' }
    }
  }, async (request, reply) => {
    const { email } = z.object({
      email: z.string().trim().email().max(254).transform((value) => value.toLowerCase()),
    }).parse(request.body);

    const user = await prisma.user.findUnique({ where: { email } });
    const code = passwordResetCode();
    if (user) {
      await prisma.passwordReset.upsert({
        where: { userId: user.id },
        create: { userId: user.id, codeHash: passwordResetHash(email, code), attemptCount: 0, expiresAt: passwordResetExpiry() },
        update: { codeHash: passwordResetHash(email, code), attemptCount: 0, expiresAt: passwordResetExpiry() },
      });
      try {
        await sendEmail({
          to: user.email,
          subject: 'Your DueNest password reset code',
          html: `<p>Use this code to reset your DueNest password:</p><p><strong>${code}</strong></p><p>This code expires in 15 minutes.</p>`,
        });
      } catch (error) {
        request.log.error({ error }, 'Password reset email delivery failed');
      }
    }
    return reply.status(200).send({
      message: 'If an account exists for this email, a reset code has been sent.',
      code: env.NODE_ENV === 'development' ? code : undefined,
    });
  });

  app.post('/api/auth/reset-password', {
    config: {
      rateLimit: { max: 5, timeWindow: '15 minutes' },
    },
  }, async (request, reply) => {
    const input = z.object({
      email: z.string().trim().email().max(254).transform((value) => value.toLowerCase()),
      code: z.string().length(6),
      newPassword: z.string().min(12).max(128),
    }).parse(request.body);

    const user = await prisma.user.findUnique({ where: { email: input.email } });
    const reset = user
      ? await prisma.passwordReset.findUnique({ where: { userId: user.id } })
      : null;
    const validCode = Boolean(user && reset && reset.expiresAt > new Date() && reset.attemptCount < 5 && hashesMatch(reset.codeHash, passwordResetHash(input.email, input.code)));
    if (!validCode || !user) {
      if (user && reset && reset.expiresAt > new Date() && reset.attemptCount < 5) {
        await prisma.passwordReset.update({ where: { userId: user.id }, data: { attemptCount: { increment: 1 } } });
      }
      return reply.status(400).send({ error: 'INVALID_CODE', message: 'The reset code is invalid or has expired.' });
    }

    const newPasswordHash = await hashPassword(input.newPassword);
    await prisma.$transaction([
      prisma.user.update({ where: { id: user.id }, data: { passwordHash: newPasswordHash } }),
      prisma.userSession.updateMany({ where: { userId: user.id, revokedAt: null }, data: { revokedAt: new Date() } }),
      prisma.passwordReset.delete({ where: { userId: user.id } }),
    ]);

    return reply.status(200).send({ message: 'Password updated successfully. You can now sign in.' });
  });
  app.patch('/api/auth/profile', {
    preHandler: async (request, reply) => {
      await requireAuthenticatedSession(request, reply);
    },
  }, async (request, reply) => {
    const input = z.object({
      displayName: z.string().trim().min(2).max(100),
      ageRange: z.enum(['UNDER_18', 'AGE_18_24', 'AGE_25_34', 'AGE_35_44', 'AGE_45_PLUS']).optional(),
      gender: z.enum(['MALE', 'FEMALE', 'PREFER_NOT_TO_SAY']).optional(),
    }).parse(request.body);
    const userId = (request.user as JwtPayload).userId;

    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        displayName: input.displayName,
        ageRange: input.ageRange,
        gender: input.gender,
      },
      select: { id: true, email: true, displayName: true, role: true, ageRange: true, gender: true }
    });

    return reply.status(200).send(updated);
  });

  app.patch('/api/auth/password', {
    preHandler: async (request, reply) => {
      await requireAuthenticatedSession(request, reply);
    },
  }, async (request, reply) => {
    const input = z.object({
      currentPassword: z.string().min(1),
      newPassword: z.string().min(12).max(128),
    }).parse(request.body);
    const userId = (request.user as JwtPayload).userId;

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !(await verifyPassword(input.currentPassword, user.passwordHash))) {
      return reply.status(400).send({ error: 'INVALID_CREDENTIALS', message: 'Current password is incorrect.' });
    }

    const newPasswordHash = await hashPassword(input.newPassword);
    await prisma.$transaction([
      prisma.user.update({ where: { id: userId }, data: { passwordHash: newPasswordHash } }),
      prisma.userSession.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);

    return reply.status(200).send({ message: 'Password updated successfully. Please sign in again.' });
  });
}
