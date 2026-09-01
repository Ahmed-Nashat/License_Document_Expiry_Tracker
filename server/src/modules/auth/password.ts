import { randomBytes, scrypt as scryptCallback, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(scryptCallback);

export async function hashPassword(password: string) {
  const salt = randomBytes(16).toString('base64url');
  const digest = await scrypt(password, salt, 64) as Buffer;
  return `scrypt$${salt}$${digest.toString('base64url')}`;
}

export async function verifyPassword(password: string, stored: string) {
  const [algorithm, salt, encodedDigest] = stored.split('$');
  if (algorithm !== 'scrypt' || !salt || !encodedDigest) return false;
  const digest = await scrypt(password, salt, 64) as Buffer;
  const expected = Buffer.from(encodedDigest, 'base64url');
  return digest.length === expected.length && timingSafeEqual(digest, expected);
}
