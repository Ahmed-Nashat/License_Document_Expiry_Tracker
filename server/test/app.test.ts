import { describe, expect, it, vi } from 'vitest';

vi.mock('../src/lib/prisma.js', () => ({ prisma: { $queryRaw: vi.fn().mockResolvedValue(1) } }));

describe('health endpoints', async () => {
  const { buildApp } = await import('../src/app.js');
  const app = buildApp();

  it('reports liveness without a database request', async () => {
    const response = await app.inject({ method: 'GET', url: '/health/live' });
    expect(response.statusCode).toBe(200);
    expect(response.json().status).toBe('ok');
  });

  it('reports readiness when PostgreSQL is available', async () => {
    const response = await app.inject({ method: 'GET', url: '/health/ready' });
    expect(response.statusCode).toBe(200);
    expect(response.json().database).toBe('ok');
  });
});
