import { createHash, randomBytes } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { env } from '../../config/env.js';
import { prisma } from '../../lib/prisma.js';
import { hashPassword, verifyPassword } from './password.js';

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
const cookieOptions = { httpOnly: true, secure: env.COOKIE_SECURE, sameSite: 'lax' as const, path: '/api/auth', domain: env.COOKIE_DOMAIN || undefined };
const refreshHash = (value: string) => createHash('sha256').update(`${env.JWT_REFRESH_SECRET}:${value}`).digest('base64url');
const refreshToken = () => randomBytes(48).toString('base64url');
const expiry = () => new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 86_400_000);
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
  
  app.post('/api/auth/register', async (request, reply) => {
    const input = registration.parse(request.body);
    if (await prisma.user.findUnique({ where: { email: input.email }, select: { id: true } })) return reply.status(409).send({ error: 'EMAIL_IN_USE', message: 'An account already exists for this email.' });
    const user = await prisma.user.create({ data: { email: input.email, passwordHash: await hashPassword(input.password), displayName: input.displayName, ageRange: input.ageRange, gender: input.gender } });
    const { rawToken, session } = await createSession(app, user.id, request.headers['user-agent']);
    reply.setCookie(cookieName, rawToken, { ...cookieOptions, expires: session.expiresAt });
    return reply.status(201).send({ accessToken: issue(user.id, user.role, session.id), user: publicUser(user) });
  });

  app.post('/api/auth/login', async (request, reply) => {
    const input = credentials.pick({ email: true, password: true }).parse(request.body);
    const user = await prisma.user.findUnique({ where: { email: input.email } });
    if (!user || !(await verifyPassword(input.password, user.passwordHash))) return reply.status(401).send({ error: 'INVALID_CREDENTIALS', message: 'Email or password is incorrect.' });
    const { rawToken, session } = await createSession(app, user.id, request.headers['user-agent']);
    reply.setCookie(cookieName, rawToken, { ...cookieOptions, expires: session.expiresAt });
    return { accessToken: issue(user.id, user.role, session.id), user: publicUser(user) };
  });

  app.post('/api/auth/refresh', async (request, reply) => {
    const rawToken = request.cookies[cookieName];
    if (!rawToken) return reply.status(401).send({ error: 'SESSION_EXPIRED', message: 'Please sign in again.' });
    const session = await prisma.userSession.findUnique({
      where: { refreshTokenHash: refreshHash(rawToken) },
      include: { user: { select: { id: true, email: true, displayName: true, role: true, ageRange: true, gender: true } } },
    });
    if (!session || session.revokedAt || session.expiresAt <= new Date()) return reply.status(401).send({ error: 'SESSION_EXPIRED', message: 'Please sign in again.' });
    const nextToken = refreshToken();
    const expiresAt = expiry();
    await prisma.userSession.update({ where: { id: session.id }, data: { refreshTokenHash: refreshHash(nextToken), lastUsedAt: new Date(), lastRefreshAt: new Date(), expiresAt } });
    reply.setCookie(cookieName, nextToken, { ...cookieOptions, expires: expiresAt });
    return { accessToken: issue(session.userId, session.user.role, session.id), user: publicUser(session.user) };
  });
  app.post('/api/auth/logout', async (request, reply) => {
    const rawToken = request.cookies[cookieName];
    if (rawToken) await prisma.userSession.updateMany({ where: { refreshTokenHash: refreshHash(rawToken), revokedAt: null }, data: { revokedAt: new Date() } });
    reply.clearCookie(cookieName, cookieOptions);
    return reply.status(204).send();
  });
  const resetCodes = new Map<string, { code: string; expiresAt: number }>();

  app.post('/api/auth/forgot-password', async (request, reply) => {
    const { email } = z.object({
      email: z.string().trim().email().max(254).transform((value) => value.toLowerCase()),
    }).parse(request.body);

    const user = await prisma.user.findUnique({ where: { email } });
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    if (user) {
      resetCodes.set(email, { code, expiresAt: Date.now() + 15 * 60 * 1000 });
    }
    return reply.status(200).send({
      message: 'Reset code generated.',
      code: env.NODE_ENV === 'development' ? code : undefined,
    });
  });

  app.post('/api/auth/reset-password', async (request, reply) => {
    const input = z.object({
      email: z.string().trim().email().max(254).transform((value) => value.toLowerCase()),
      code: z.string().length(6),
      newPassword: z.string().min(12).max(128),
    }).parse(request.body);

    const entry = resetCodes.get(input.email);
    if (!entry || entry.code !== input.code || entry.expiresAt < Date.now()) {
      return reply.status(400).send({ error: 'INVALID_CODE', message: 'The reset code is invalid or has expired.' });
    }

    const user = await prisma.user.findUnique({ where: { email: input.email } });
    if (!user) {
      return reply.status(404).send({ error: 'USER_NOT_FOUND', message: 'Account not found.' });
    }

    const newPasswordHash = await hashPassword(input.newPassword);
    await prisma.user.update({ where: { email: input.email }, data: { passwordHash: newPasswordHash } });
    await prisma.userSession.updateMany({ where: { userId: user.id, revokedAt: null }, data: { revokedAt: new Date() } });
    resetCodes.delete(input.email);

    return reply.status(200).send({ message: 'Password updated successfully. You can now sign in.' });
  });
}
