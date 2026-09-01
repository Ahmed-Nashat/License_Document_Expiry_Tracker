import { describe, expect, it } from 'vitest';
import { hashPassword, verifyPassword } from '../src/modules/auth/password.js';

describe('password hashing', () => {
  it('verifies the original password and rejects an incorrect one', async () => {
    const hash = await hashPassword('a strong test password');
    await expect(verifyPassword('a strong test password', hash)).resolves.toBe(true);
    await expect(verifyPassword('another password entirely', hash)).resolves.toBe(false);
  });
});
