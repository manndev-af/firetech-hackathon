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
  const chunks = [];
  prisma.getPrismaClient = () => ({ $transaction: async callback => callback({
    user: { upsert: async () => ({ id: 'fixture-user' }) },
    nutritionProfile: { upsert: async ({ create, update }) => { created = create; assert.deepEqual(update, {}); } },
    knowledgeChunk: { upsert: async ({ where, create, update }) => {
      assert.equal(where.id, create.id);
      assert.deepEqual(update, create);
      chunks.push(create);
    } },
  }) });
  try {
    await seed();
    const { userId, ...profile } = created;
    assert.equal(userId, 'fixture-user');
    assert.deepEqual(Object.keys(profile).sort(), Object.keys(profileProperties).sort());
    assert.ok(Object.values(profile).every(value => value !== null && value !== undefined && value !== ''));
    assert.ok(profile.priorities.length && profile.allergies.length);
    assert.doesNotThrow(() => mergeProfile(profile, profile));
    const { knowledge, kemenkesKnowledge } = require('../prisma/knowledge');
    assert.deepEqual(chunks, knowledge);
    assert.equal(kemenkesKnowledge.length, 11);
    assert.equal(chunks.length, 14);
    assert.ok(kemenkesKnowledge.every(chunk => chunk.reviewed && chunk.sourceUrl ===
      'https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf'));
    assert.equal(new Set(chunks.map(chunk => chunk.id)).size, chunks.length);
    const tags = ['Gula', 'Natrium', 'Protein', 'Kalori', 'Keseimbangan'];
    for (const chunk of chunks) {
      for (const [field, limit] of Object.entries({ id: 80, title: 160, sourceUrl: 512, sourceTitle: 160, version: 40, license: 255 })) {
        assert.ok(chunk[field].length > 0 && [...chunk[field]].length <= limit, `${chunk.id}: ${field}`);
      }
      assert.ok(chunk.text.trim());
      assert.ok(chunk.tags.length && chunk.tags.every(tag => tags.includes(tag)));
      if (chunk.reviewed) {
        assert.ok(chunk.reviewedAt instanceof Date && Number.isFinite(chunk.reviewedAt.getTime()));
        assert.ok(/^https:\/\//.test(chunk.sourceUrl));
        assert.ok(!chunk.sourceUrl.includes('REPLACE_WITH'));
      }
    }
  } finally { prisma.getPrismaClient = original; }
});
