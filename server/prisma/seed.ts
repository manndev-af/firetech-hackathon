import 'dotenv/config';
import { randomBytes, scrypt } from 'node:crypto';
import { promisify } from 'node:util';
import { getPrismaClient } from '../src/config/prisma';
import { knowledge } from './knowledge';

export async function seed() {
  if (!['development', 'test'].includes(process.env.NODE_ENV || '')) throw new Error('Seed is development/test only.');
  const email = process.env.SEED_USER_EMAIL?.trim().toLowerCase();
  const password = process.env.SEED_USER_PASSWORD;
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254 || !password || password.length < 5 || password.length > 128) throw new Error('Set valid SEED_USER_EMAIL and SEED_USER_PASSWORD (5-128 characters).');
  const salt = randomBytes(16).toString('hex');
  const hash = await promisify(scrypt)(password, salt, 64) as Buffer;
  const passwordHash = `scrypt:${salt}:${hash.toString('hex')}`;
  const db = getPrismaClient();
  await db.$transaction(async tx => {
    const user = await tx.user.upsert({ where: { email }, update: {}, create: { email, passwordHash } });
    await tx.nutritionProfile.upsert({ where: { userId: user.id }, update: {}, create: {
      userId: user.id,
      name: 'Pengguna Demo',
      age: 25,
      heightCm: 165,
      weightKg: 60,
      preference: 'Masakan rumahan',
      priorities: ['Gula', 'Protein'],
      eatingPattern: 'Fleksibel',
      prefersHalal: true,
      allergyStatus: 'listed',
      allergies: ['Susu'],
      otherAllergies: 'Wijen',
      audioAnalysisEnabled: true,
      timezone: 'Asia/Jakarta',
    } });
    for (const chunk of knowledge) await tx.knowledgeChunk.upsert({ where: { id: chunk.id }, update: chunk, create: chunk });
  });
}

if (require.main === module) {
  seed().catch(() => { console.error('Seed failed. Check development configuration and database availability; no credentials printed.'); process.exitCode = 1; })
    .finally(async () => { try { if (process.env.DATABASE_URL) await getPrismaClient().$disconnect(); } catch { process.exitCode = 1; } });
}
