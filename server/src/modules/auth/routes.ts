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

const cookieName = 'deunest_refresh';
const cookieOptions = { httpOnly: true, secure: env.COOKIE_SECURE, sameSite: 'lax' as const, path: '/api/auth', domain: env.COOKIE_DOMAIN || undefined };
const refreshHash = (value: string) => createHash('sha256').update(`${env.JWT_REFRESH_SECRET}:${value}`).digest('base64url');
const refreshToken = () => randomBytes(48).toString('base64url');
const expiry = () => new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 86_400_000);

async function createSession(app: FastifyInstance, userId: string, deviceName?: string) {
  const rawToken = refreshToken();
  const session = await prisma.userSession.create({ data: { userId, refreshTokenHash: refreshHash(rawToken), deviceName: deviceName?.slice(0, 160), deviceType: 'web', expiresAt: expiry() } });
  const oldSessions = await prisma.userSession.findMany({ where: { userId, revokedAt: null, expiresAt: { gt: new Date() } }, orderBy: { lastUsedAt: 'desc' }, skip: 2, select: { id: true } });
  if (oldSessions.length) await prisma.userSession.updateMany({ where: { id: { in: oldSessions.map((sessionItem) => sessionItem.id) } }, data: { revokedAt: new Date() } });
  return { rawToken, session };
}

export async function authRoutes(app: FastifyInstance) {
  const issue = (userId: string, sessionId: string) => app.jwt.sign({ userId, sessionId }, { expiresIn: `${env.ACCESS_TOKEN_TTL_MINUTES}m` });
  app.post('/api/auth/register', { config: { rateLimit: { max: 5, timeWindow: '1 hour' } } }, async (request, reply) => {
    const input = credentials.parse(request.body);
    if (await prisma.user.findUnique({ where: { email: input.email }, select: { id: true } })) return reply.status(409).send({ error: 'EMAIL_IN_USE', message: 'An account already exists for this email.' });
    const user = await prisma.user.create({ data: { email: input.email, passwordHash: await hashPassword(input.password), displayName: input.displayName } });
    const { rawToken, session } = await createSession(app, user.id, request.headers['user-agent']);
    reply.setCookie(cookieName, rawToken, { ...cookieOptions, expires: session.expiresAt });
    return reply.status(201).send({ accessToken: issue(user.id, session.id), user: { id: user.id, email: user.email, displayName: user.displayName } });
  });
  app.post('/api/auth/login', { config: { rateLimit: { max: 10, timeWindow: '15 minutes' } } }, async (request, reply) => {
    const input = credentials.pick({ email: true, password: true }).parse(request.body);
    const user = await prisma.user.findUnique({ where: { email: input.email } });
    if (!user || !(await verifyPassword(input.password, user.passwordHash))) return reply.status(401).send({ error: 'INVALID_CREDENTIALS', message: 'Email or password is incorrect.' });
    const { rawToken, session } = await createSession(app, user.id, request.headers['user-agent']);
    reply.setCookie(cookieName, rawToken, { ...cookieOptions, expires: session.expiresAt });
    return { accessToken: issue(user.id, session.id), user: { id: user.id, email: user.email, displayName: user.displayName } };
  });
  app.post('/api/auth/refresh', { config: { rateLimit: { max: 30, timeWindow: '15 minutes' } } }, async (request, reply) => {
    const rawToken = request.cookies[cookieName];
    if (!rawToken) return reply.status(401).send({ error: 'SESSION_EXPIRED', message: 'Please sign in again.' });
    const session = await prisma.userSession.findUnique({ where: { refreshTokenHash: refreshHash(rawToken) } });
    if (!session || session.revokedAt || session.expiresAt <= new Date()) return reply.status(401).send({ error: 'SESSION_EXPIRED', message: 'Please sign in again.' });
    const nextToken = refreshToken();
    const expiresAt = expiry();
    await prisma.userSession.update({ where: { id: session.id }, data: { refreshTokenHash: refreshHash(nextToken), lastUsedAt: new Date(), lastRefreshAt: new Date(), expiresAt } });
    reply.setCookie(cookieName, nextToken, { ...cookieOptions, expires: expiresAt });
    return { accessToken: issue(session.userId, session.id) };
  });
  app.post('/api/auth/logout', async (request, reply) => {
    const rawToken = request.cookies[cookieName];
    if (rawToken) await prisma.userSession.updateMany({ where: { refreshTokenHash: refreshHash(rawToken), revokedAt: null }, data: { revokedAt: new Date() } });
    reply.clearCookie(cookieName, cookieOptions);
    return reply.status(204).send();
  });
}
