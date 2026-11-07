const assert = require('node:assert/strict');
const { test } = require('node:test');
const { once } = require('node:events');
const { randomUUID, createHash } = require('node:crypto');

test('scanner HTTP, Prisma persistence, retrieval and one-dispatch lifecycle', { skip: !process.env.TEST_DATABASE_URL }, async t => {
  const database = new URL(process.env.TEST_DATABASE_URL);
  assert.ok(database.pathname.endsWith('_test'), 'Use an isolated database ending in _test');
  process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
  process.env.NODE_ENV = 'test';
  process.env.API_PREFIX = '/api';
  process.env.RATE_LIMIT_MAX_REQUESTS = '1000';
  process.env.ENABLE_DEMO_USER = 'true';
  process.env.SEED_USER_EMAIL = `scanner-${randomUUID()}@nutrilens.test`;
  process.env.DEMO_USER_EMAIL = process.env.SEED_USER_EMAIL;
  process.env.SEED_USER_PASSWORD = 'synthetic-test-password';
  process.env.DEEPSEEK_API_KEY = 'mock-only';
  process.env.DEEPSEEK_BASE_URL = 'https://deepseek.integration.test';
  require('ts-node/register');
  const sharp = require('sharp');
  const { seed } = require('../prisma/seed');
  const { getPrismaClient } = require('../src/config/prisma');
  const { createApp } = require('../src/app');
  const { retrieveContext } = require('../src/services/retrieval.service');
  const { nutrients, priorities, allergens } = require('../src/validation/nutrition');
  const db = getPrismaClient();
  const realFetch = global.fetch;
  let calls = 0;
  let failure = false;
  let invalid = false;
  let providerDelay = 25;
  let captured;
  global.fetch = async (url, options) => {
    if (url !== 'https://deepseek.integration.test/chat/completions') return realFetch(url, options);
    calls++;
    const request = JSON.parse(options.body);
    captured = JSON.parse(request.messages[1].content[0].text);
    assert.match(request.messages[1].content[1].image_url.url, /^data:image\/jpeg;base64,/);
    await new Promise(resolve => setTimeout(resolve, providerDelay));
    if (failure) return new Response('mock failure', { status: 503 });
    const mode = captured.mode;
    const analysis = { status: mode, identity: 'Synthetic fixture',
      portion: { baseQuantity: 1, unitCode: 'porsi', displayLabel: '1 porsi', basis: 'per_serving', originalServingText: mode === 'label' ? 'Takaran saji 100 g' : null, referenceWeightG: 100, referenceVolumeMl: null },
      nutrients: Object.fromEntries(nutrients.map(key => [key, key === 'protein_g' ? 5 : null])),
      evidence: Object.fromEntries(nutrients.map(key => [key, key === 'protein_g' && mode === 'label' ? { origin: 'ocr', text: 'Protein 5 g' } : null])),
      warnings: ['Data sintetis untuk pengujian.'], advantages: ['Protein mendukung fokus protein Anda.'], tradeoffs: ['Gula belum diketahui untuk menilai fokus gula Anda.'], citationIds: [],
      ttsSummary: 'Nilai nutrisi masih berupa perkiraan. Periksa porsi dan data yang belum lengkap.',
    };
    return Response.json({ choices: [{ finish_reason: 'stop', message: { content: invalid ? '{broken' : JSON.stringify(analysis) } }] });
  };
  const image = await sharp({ create: { width: 16, height: 16, channels: 3, background: '#fff' } }).png().toBuffer();
  let server;
  let user;
  let stranger;
  const knowledgeId = `unreviewed-${randomUUID()}`;
  try {
    await seed();
    user = await db.user.findUniqueOrThrow({ where: { email: process.env.SEED_USER_EMAIL }, include: { profile: true } });
    await t.test('complete demo seed, hash, guards and unique constraints', async () => {
      assert.match(user.passwordHash, /^scrypt:[a-f0-9]{32}:[a-f0-9]{128}$/);
      assert.ok(!user.passwordHash.includes(process.env.SEED_USER_PASSWORD));
      assert.deepEqual(user.profile.priorities, ['Gula', 'Protein']);
      assert.equal(user.profile.audioAnalysisEnabled, true);
      assert.equal(user.profile.age, 25);
      assert.ok(Object.values(user.profile).every(value => value !== null));
      await assert.rejects(db.user.create({ data: { email: user.email, passwordHash: 'fixture' } }), { code: 'P2002' });
      process.env.NODE_ENV = 'production'; await assert.rejects(seed());
      process.env.NODE_ENV = 'test';
      const password = process.env.SEED_USER_PASSWORD;
      delete process.env.SEED_USER_PASSWORD; await assert.rejects(seed());
      process.env.SEED_USER_PASSWORD = password;
    });
    server = createApp().listen(0, '127.0.0.1');
    await once(server, 'listening');
    const base = `http://127.0.0.1:${server.address().port}/api/v1`;
    const request = (path, options) => realFetch(`${base}${path}`, options);
    const patch = (path, data) => request(path, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) });
    const scan = (key = randomUUID(), fields = {}, bytes = image, type = 'image/png') => {
      const body = new FormData();
      body.append('mode', fields.mode || 'food');
      for (const [name, value] of Object.entries(fields)) if (name !== 'mode') body.append(name, value);
      body.append('image', new Blob([bytes], { type }), 'fixture.png');
      return request('/scans', { method: 'POST', headers: { 'Idempotency-Key': key }, body });
    };
    await t.test('profile groups persist all Flutter fields and seed preserves edits', async () => {
      assert.equal((await patch('/profile', { name: ' Naya ', age: 22 })).status, 200);
      const complete = { heightCm: 165.5, weightKg: 58.25, preference: 'Masakan rumahan', priorities: [...priorities], eatingPattern: 'Vegetarian', prefersHalal: true, allergyStatus: 'listed', allergies: [...allergens], otherAllergies: 'Wijen', audioAnalysisEnabled: true, timezone: 'Asia/Jakarta' };
      const response = await patch('/profile', complete);
      assert.equal(response.status, 200, await response.clone().text());
      const profile = (await response.json()).data;
      for (const [name, value] of Object.entries(complete)) assert.deepEqual(profile[name], value, name);
      await seed();
      const persisted = await db.user.findUniqueOrThrow({ where: { id: user.id }, include: { profile: true } });
      assert.equal(persisted.passwordHash, user.passwordHash);
      assert.equal(persisted.profile.name, 'Naya');
      assert.equal(persisted.profile.audioAnalysisEnabled, true);
      assert.equal((await patch('/profile', { age: null, heightCm: null, weightKg: null })).status, 200);
      assert.equal((await patch('/profile', { userId: randomUUID() })).status, 400);
      assert.equal((await patch('/profile', { priorities: [] })).status, 400);
      const malformed = await request('/profile', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: '{broken' });
      assert.equal(malformed.status, 400);
      assert.equal((await malformed.json()).data.code, 'INVALID_JSON');
      assert.equal((await request('/profile', { headers: { 'x-user-id': randomUUID() } })).status, 400);
      process.env.ENABLE_DEMO_USER = 'false'; assert.equal((await request('/profile')).status, 404);
      process.env.ENABLE_DEMO_USER = 'true'; process.env.NODE_ENV = 'production'; assert.equal((await request('/profile')).status, 404);
      process.env.NODE_ENV = 'test'; process.env.DEMO_USER_EMAIL = 'missing@nutrilens.test'; assert.equal((await request('/profile')).status, 503);
      process.env.DEMO_USER_EMAIL = user.email;
    });
    await t.test('invalid uploads never call provider', async () => {
      const before = calls;
      for (const args of [
        [randomUUID(), { mode: 'label', rawOcrText: ' ' }],
        [randomUUID(), { imageUrl: 'https://example.com/image.jpg' }],
        [randomUUID(), {}, image, 'image/jpeg'],
        [randomUUID(), {}, Buffer.from('broken')],
        [randomUUID(), {}, Buffer.alloc(5 * 1024 * 1024 + 1)],
      ]) assert.ok((await scan(...args)).status >= 400);
      const huge = await sharp({ create: { width: 4500, height: 4500, channels: 3, background: '#fff' } }).png().toBuffer();
      assert.equal((await scan(randomUUID(), {}, huge)).status, 415);
      const form = new FormData(); form.append('mode', 'food'); form.append('mode', 'label'); form.append('image', new Blob([image], { type: 'image/png' }), 'fixture.png');
      assert.equal((await request('/scans', { method: 'POST', headers: { 'Idempotency-Key': randomUUID() }, body: form })).status, 400);
      assert.equal(calls, before);
    });
    let entry;
    const key = randomUUID();
    await t.test('food auto-save, replay without key configuration, conflict and Decimal quantity', async () => {
      const response = await scan(key);
      assert.equal(response.status, 201, await response.clone().text());
      entry = (await response.json()).data;
      assert.equal(entry.provenance, 'model_estimate');
      assert.equal(entry.nutrients.protein_g, 5);
      assert.equal(entry.nutrients.sugar_g, null);
      assert.equal(entry.context.recordedDaily.entryCount, 0);
      assert.deepEqual(entry.pros, entry.analysis.advantages);
      assert.deepEqual(entry.cons, entry.analysis.tradeoffs);
      assert.equal(calls, 1);
      delete process.env.DEEPSEEK_API_KEY;
      assert.equal((await scan(key)).status, 200);
      process.env.DEEPSEEK_API_KEY = 'mock-only';
      assert.equal((await scan(key, { description: 'different' })).status, 409);
      for (const quantity of [2, 0.5, 1]) {
        const updated = await patch(`/food-entries/${entry.id}/quantity`, { quantity });
        assert.equal(updated.status, 200);
        const value = (await updated.json()).data;
        assert.equal(value.nutrients.protein_g, 5 * quantity);
        assert.equal(value.nutrients.sugar_g, null);
        assert.equal(value.ttsSummary, entry.ttsSummary);
        assert.deepEqual(value.pros, entry.pros);
        assert.deepEqual(value.cons, entry.cons);
      }
      assert.equal((await patch(`/food-entries/${entry.id}/quantity`, { quantity: 0 })).status, 400);
      assert.equal(calls, 1);
      await seed(); assert.equal(await db.foodEntry.count({ where: { userId: user.id } }), 1);
    });
    await t.test('label scan, concurrent duplicate and durable dispatch state', async () => {
      const duplicate = randomUUID();
      const before = calls;
      const responses = await Promise.all([scan(duplicate, { mode: 'label', rawOcrText: 'Takaran saji 100 g\nProtein 5 g' }), scan(duplicate, { mode: 'label', rawOcrText: 'Takaran saji 100 g\nProtein 5 g' })]);
      assert.equal(responses.filter(response => response.status === 201).length, 1);
      assert.ok(responses.every(response => [200, 201, 409].includes(response.status)));
      assert.equal(calls, before + 1);
      const label = (await responses.find(response => response.status === 201).json()).data;
      assert.equal(label.provenance, 'label_extracted_unverified');
      assert.equal(label.nutrients.protein_g, 5);
      assert.match(captured.rawOcrText, /Protein/);
      const unresolved = randomUUID();
      const fingerprint = createHash('sha256').update(image).update(JSON.stringify({ mode: 'food', description: '', rawOcrText: '', quantity: null, consumedAt: null })).digest('hex');
      await db.scanRequest.create({ data: { userId: user.id, key: unresolved, fingerprint, state: 'dispatched', dispatchedAt: new Date() } });
      await assert.rejects(db.scanRequest.create({ data: { userId: user.id, key: unresolved, fingerprint } }), { code: 'P2002' });
      const pending = await scan(unresolved); assert.equal(pending.status, 409);
      assert.equal((await pending.json()).data.code, 'DISPATCH_UNCERTAIN');
      assert.equal(calls, before + 1);
    });
    await t.test('provider failures never save entries or retry', async () => {
      const count = await db.foodEntry.count({ where: { userId: user.id } });
      for (const kind of ['failure', 'invalid']) {
        failure = kind === 'failure'; invalid = kind === 'invalid';
        const failedKey = randomUUID(); const before = calls;
        assert.equal((await scan(failedKey)).status, 502);
        assert.equal((await scan(failedKey)).status, 502);
        assert.equal(calls, before + 1);
        assert.equal(await db.foodEntry.count({ where: { userId: user.id } }), count);
      }
      failure = false; invalid = false;
    });
    await t.test('scan concurrency is bounded and database rollback prevents phantom consumption', async () => {
      providerDelay = 150;
      const before = calls;
      const scans = await Promise.all([scan(), scan(), scan()]);
      providerDelay = 25;
      assert.equal(scans.filter(response => response.status === 429).length, 1);
      assert.equal(calls, before + 2);
      for (const response of scans.filter(response => response.status === 201)) {
        const created = (await response.json()).data;
        await request(`/food-entries/${created.id}`, { method: 'DELETE' });
      }
      const { createScan } = require('../src/services/scan.service');
      const { validateAnalysis } = require('../src/services/deepseek.service');
      const transaction = db.$transaction.bind(db);
      const count = await db.foodEntry.count({ where: { userId: user.id } });
      let dispatches = 0;
      const scanInput = { key: randomUUID(), mode: 'food', description: '', rawOcrText: '', quantity: 1, consumedAt: new Date(), image, original: image, fingerprintMetadata: {} };
      const provider = async () => {
        dispatches++;
        db.$transaction = callback => transaction(tx => callback(new Proxy(tx, { get(target, name) {
          if (name === 'scanRequest') return { update: async () => { throw new Error('Synthetic transaction failure'); } };
          return target[name];
        } })));
        return validateAnalysis({ status: 'food', identity: 'Rollback fixture', portion: { baseQuantity: 1, unitCode: 'porsi', displayLabel: '1 porsi', basis: 'per_serving', originalServingText: null, referenceWeightG: null, referenceVolumeMl: null }, nutrients: Object.fromEntries(nutrients.map(key => [key, null])), evidence: Object.fromEntries(nutrients.map(key => [key, null])), warnings: [], advantages: [], tradeoffs: [], citationIds: [] }, 'food', '', []);
      };
      try { await assert.rejects(createScan(user.id, scanInput, provider), { code: 'SCAN_STORAGE_FAILED' }); }
      finally { db.$transaction = transaction; }
      assert.equal(await db.foodEntry.count({ where: { userId: user.id } }), count);
      await assert.rejects(createScan(user.id, scanInput, provider), { code: 'SCAN_STORAGE_FAILED' });
      assert.equal(dispatches, 1);
    });
    await t.test('owner isolation, bounded retrieval, reviewed sources and deleted tombstone', async () => {
      stranger = await db.user.create({ data: { email: `stranger-${randomUUID()}@nutrilens.test`, passwordHash: 'synthetic' } });
      const foreign = await db.foodEntry.create({ data: { userId: stranger.id, mode: 'food', title: 'PRIVATE', description: '', consumedAt: new Date(), quantity: 1, baseQuantity: 1, provenance: 'model_estimate', analysis: {}, context: {}, model: 'fixture', promptVersion: 'fixture' } });
      assert.equal((await request(`/food-entries/${foreign.id}`)).status, 404);
      assert.equal((await patch(`/food-entries/${foreign.id}/quantity`, { quantity: 2 })).status, 404);
      assert.equal((await request(`/food-entries/${foreign.id}`, { method: 'DELETE' })).status, 404);
      const source = await db.knowledgeChunk.findFirstOrThrow();
      await db.knowledgeChunk.create({ data: { ...source, id: knowledgeId, reviewed: false } });
      const profile = await db.nutritionProfile.findUniqueOrThrow({ where: { userId: user.id } });
      const context = await retrieveContext(user.id, profile, new Date(Date.now() + 1000), 'Protein Gula');
      assert.ok(context.history.length > 0 && context.history.length <= 5);
      assert.ok(context.references.length > 0 && context.references.length <= 3);
      assert.ok(!context.references.some(ref => ref.id === knowledgeId));
      assert.ok(!context.history.some(item => item.title === 'PRIVATE'));
      const repeat = await retrieveContext(user.id, profile, new Date(Date.now() + 1000), 'Protein Gula');
      assert.deepEqual(repeat.history.map(item => item.id), context.history.map(item => item.id));
      const backdated = await retrieveContext(user.id, profile, new Date(entry.consumedAt), 'Protein');
      assert.ok(!backdated.history.some(item => new Date(item.consumedAt) >= new Date(entry.consumedAt)));
      assert.ok(JSON.stringify(context).length <= 8000);
      const longId = `000-${knowledgeId}`;
      try {
        await db.knowledgeChunk.create({ data: { ...source, id: longId, reviewed: true, text: 'Protein '.repeat(2000) } });
        const bounded = await retrieveContext(user.id, profile, new Date(Date.now() + 1000), 'Protein');
        assert.ok(JSON.stringify(bounded).length <= 8000);
        assert.ok(!bounded.references.some(ref => ref.id === longId));
      } finally { await db.knowledgeChunk.deleteMany({ where: { id: longId } }); }
      for (const field of ['name', 'age', 'heightCm', 'weightKg', 'audioAnalysisEnabled', 'email', 'passwordHash']) assert.ok(!(field in context.profile));
      const cold = await retrieveContext(user.id, { ...profile, priorities: [] }, new Date('2020-01-01T00:00:00Z'), 'zzzznomatch');
      assert.equal(cold.historyAvailable, false); assert.equal(cold.referencesAvailable, false);
      const total = (await (await request('/nutrition/daily')).json()).data;
      assert.equal(total.entryCount, 2); assert.equal(total.nutrients.protein_g.knownTotal, 10);
      assert.equal(total.nutrients.sugar_g.knownTotal, null);
      assert.equal((await request('/food-entries?page=0')).status, 400);
      assert.equal((await request('/food-entries?limit=101')).status, 400);
      assert.equal((await request('/food-entries?limit=1')).status, 200);
      assert.equal((await request(`/food-entries/${entry.id}`, { method: 'DELETE' })).status, 204);
      assert.equal((await scan(key)).status, 410);
      const after = (await (await request('/nutrition/daily')).json()).data;
      assert.equal(after.entryCount, 1); assert.equal(after.nutrients.protein_g.knownTotal, 5);
      const refreshed = await retrieveContext(user.id, profile, new Date(Date.now() + 1000), 'Protein');
      assert.ok(!refreshed.history.some(item => item.id === entry.id));
    });
  } finally {
    global.fetch = realFetch;
    if (server) { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
    for (const owner of [user, stranger].filter(Boolean)) {
      await db.scanRequest.deleteMany({ where: { userId: owner.id } });
      await db.foodEntry.deleteMany({ where: { userId: owner.id } });
      await db.nutritionProfile.deleteMany({ where: { userId: owner.id } });
      await db.user.delete({ where: { id: owner.id } });
    }
    await db.knowledgeChunk.deleteMany({ where: { id: knowledgeId } });
    await db.$disconnect();
  }
});
