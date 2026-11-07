const assert = require('node:assert/strict');
const { test } = require('node:test');
require('ts-node/register');
const prisma = require('../src/config/prisma');
const { seed } = require('../prisma/seed');

test('development seed accepts 5-128 characters and rejects passwords outside bounds before database access', async () => {
  process.env.NODE_ENV = 'test';
  process.env.SEED_USER_EMAIL = 'boundary@nutrilens.test';
  const original = prisma.getPrismaClient;
  const reachedDatabase = new Error('Validation passed; no real database contacted.');
  prisma.getPrismaClient = () => { throw reachedDatabase; };
  try {
    for (const length of [0, 4, 129]) {
      process.env.SEED_USER_PASSWORD = 'x'.repeat(length);
      await assert.rejects(seed(), error => error !== reachedDatabase && /5-128/.test(error.message));
    }
    for (const length of [5, 128]) {
      process.env.SEED_USER_PASSWORD = 'x'.repeat(length);
      await assert.rejects(seed(), error => error === reachedDatabase);
    }
    process.env.NODE_ENV = 'production';
    await assert.rejects(seed(), /development\/test only/);
  } finally { prisma.getPrismaClient = original; }
});

test('seed creates a complete valid demo profile while preserving existing edits', async () => {
  process.env.NODE_ENV = 'test';
  process.env.SEED_USER_EMAIL = 'fixture@nutrilens.test';
  process.env.SEED_USER_PASSWORD = '12345';
  const { mergeProfile } = require('../src/services/profile.service');
  const { profileProperties } = require('../src/validation/nutrition');
  const original = prisma.getPrismaClient;
  let created;
  prisma.getPrismaClient = () => ({ $transaction: async callback => callback({
    user: { upsert: async () => ({ id: 'fixture-user' }) },
    nutritionProfile: { upsert: async ({ create, update }) => { created = create; assert.deepEqual(update, {}); } },
    knowledgeChunk: { upsert: async () => {} },
  }) });
  try {
    await seed();
    const { userId, ...profile } = created;
    assert.equal(userId, 'fixture-user');
    assert.deepEqual(Object.keys(profile).sort(), Object.keys(profileProperties).sort());
    assert.ok(Object.values(profile).every(value => value !== null && value !== undefined && value !== ''));
    assert.ok(profile.priorities.length && profile.allergies.length);
    assert.doesNotThrow(() => mergeProfile(profile, profile));
  } finally { prisma.getPrismaClient = original; }
});
