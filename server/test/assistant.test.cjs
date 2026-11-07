const { test } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const http = require('node:http');
process.env.NODE_ENV = 'test';
process.env.API_PREFIX = '/custom';
process.env.ENABLE_DEMO_USER = 'false';
require('ts-node/register');
const { readAssistantInput } = require('../src/validation/assistant');
const { createApp } = require('../src/app');
const question = () => ({ mode: 'general', message: 'Apa yang perlu diperhatikan saat memilih camilan?' });
async function serving(app, run) {
  const server = app.listen(0, '127.0.0.1'); await once(server, 'listening');
  try { await run(`http://127.0.0.1:${server.address().port}`); }
  finally { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
}

test('assistant validates Unicode text and completed history without trusting extra roles or fields', () => {
  assert.deepEqual(readAssistantInput(question()).history, []);
  const pairs = [{ role: 'user', text: '  Pertanyaan  ' }, { role: 'assistant', text: ' Jawaban ' }];
  assert.equal(readAssistantInput({ ...question(), history: pairs }).history[0].text, 'Pertanyaan');
  assert.equal([...readAssistantInput({ ...question(), message: '🍎'.repeat(2000) }).message].length, 2000);
  const bad = [{}, null, { ...question(), mode: 'compare' }, { ...question(), message: ' ' },
    ...['userId', 'system', 'image', 'compareSnapshot'].map(key => ({ ...question(), [key]: 'bad' })),
    { ...question(), message: '🍎'.repeat(2001) }, { ...question(), history: [pairs[0]] },
    ...['system', 'tool', 'assistant'].map(role => ({ ...question(), history: [{ role, text: 'text' }, pairs[1]] })),
    { ...question(), history: [pairs[0], { ...pairs[1], extra: true }] },
    { ...question(), history: [{ role: 'user', text: '' }, pairs[1]] },
    { ...question(), history: Array(6).fill(pairs).flat() },
    { ...question(), history: Array(3).fill([{ role: 'user', text: 'x'.repeat(2000) }, { role: 'assistant', text: 'x'.repeat(2000) }]).flat() },
  ];
  for (const value of bad) assert.throws(() => readAssistantInput(value), { code: 'INVALID_INPUT' });
});

test('assistant parser enforces bytes, encoding and domain errors before routing with custom prefix', async () => {
  await serving(createApp(), async base => {
    const morgan = require('morgan');
    assert.equal(morgan['safe-url']({ path: '/CUSTOM/V1/ASSISTANT/MESSAGES/', originalUrl: '/CUSTOM/V1/ASSISTANT/MESSAGES/?text=private' }), '/CUSTOM/V1/ASSISTANT/MESSAGES/');
    assert.equal(morgan['safe-url']({ path: '/custom/users', originalUrl: '/custom/users?page=1' }), '/custom/users?page=1');
    const url = `${base}/CUSTOM/V1/ASSISTANT/MESSAGES/`;
    for (const [body, headers, status] of [
      ['{', { 'Content-Type': 'application/json' }, 400],
      ['{}', { 'Content-Type': 'text/plain' }, 415],
      ['{}', { 'Content-Type': 'application/json; charset=iso-8859-1' }, 415],
      ['{}', { 'Content-Type': 'application/json', 'Content-Encoding': 'gzip' }, 415],
      [JSON.stringify({ message: 'x'.repeat(65536) }), { 'Content-Type': 'application/json' }, 413],
    ]) {
      const response = await fetch(url, { method: 'POST', headers, body });
      assert.equal(response.status, status);
      const value = await response.json(); assert.equal(value.success, false); assert.ok(value.data.code);
    }
    const chunked = await new Promise((resolve, reject) => {
      const request = http.request(url, { method: 'POST', headers: { 'Content-Type': 'application/json' } }, res => {
        let text = ''; res.on('data', chunk => text += chunk); res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(text) }));
      });
      request.on('error', reject); request.write('{"message":"'); request.end('x'.repeat(65536) + '"}');
    });
    assert.equal(chunked.status, 413); assert.equal(chunked.body.data.code, 'UPLOAD_TOO_LARGE');
    // Existing global JSON limit remains 10 MB rather than 64 KiB.
    assert.equal((await fetch(`${base}/custom/users`, { method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Test', email: 'test@example.com', extra: 'x'.repeat(70000) }) })).status, 201);
  });
});

const { Prisma } = require('../src/generated/prisma/client');
const { nutrients } = require('../src/validation/nutrition');
const { patternWindow, buildPattern, boundAssistantContext, analyzeAssistant, createAssistantMessage, assistantPrompt } = require('../src/services/assistant.service');
const { assistantResponseSchema, assistantGeneralExample, assistantPatternExample } = require('../src/routes/assistant.openapi');
const ajv = new (require('ajv'))({ strict: false }); require('ajv-formats')(ajv);
const validateResponse = ajv.compile(assistantResponseSchema);
const snapshot = new Date('2026-11-08T05:00:00Z');
const profile = { name: 'private-name', email: 'private-email', passwordHash: 'private-password', age: 39, heightCm: 170, weightKg: 80,
  priorities: ['Gula', 'Protein'], preference: 'Masakan rumahan', eatingPattern: 'Fleksibel', prefersHalal: false,
  allergyStatus: 'unknown', allergies: [], otherAllergies: '', timezone: 'Asia/Jakarta' };
const reference = { id: 'reviewed-fixture', title: 'Synthetic reference', text: 'Synthetic reviewed context, not real nutrition guidance.',
  sourceTitle: 'Test fixture', sourceUrl: 'https://example.test/reference', version: 'test-v1', reviewedAt: snapshot.toISOString() };
const assistantContext = () => ({ snapshotAt: snapshot.toISOString(), timezone: profile.timezone,
  profile: { priorities: profile.priorities }, references: [reference], historyExamples: [], patternEvidence: null });
function entry(title, date, sugar, quantity = 1) {
  return { id: `${title}-${date}`, title, consumedAt: new Date(date), quantity: new Prisma.Decimal(quantity), baseQuantity: new Prisma.Decimal(1),
    ...Object.fromEntries(nutrients.map(key => [key, null])), sugar_g: sugar === null ? null : new Prisma.Decimal(sugar), provenance: 'model_estimate' };
}
const provider = (value = { reply: 'Cek porsi dan gula sesuai prioritasmu. Informasi yang tersedia masih terbatas.', citationIds: [] }) =>
  Response.json({ choices: [{ finish_reason: 'stop', message: { content: JSON.stringify(value) } }] });

test('pattern evidence uses seven local calendar dates, Decimal quantities, null and coverage', () => {
  const data = [entry(' Teh ', '2026-11-01T17:00:00Z', 12, 0.5), // Jakarta Nov 2, inclusive start.
    entry('teh', '2026-11-07T18:00:00Z', null), entry('Air', '2026-11-08T03:00:00Z', 0),
    entry('Old', '2026-11-01T16:59:59Z', 99), entry('Future', snapshot.toISOString(), 99)];
  const result = buildPattern(data, snapshot, profile.timezone);
  assert.equal(result.dateFrom, '2026-11-02'); assert.equal(result.dateTo, '2026-11-08');
  assert.equal(result.entryCount, 3); assert.equal(result.daysWithEntries, 2);
  assert.equal(result.dailySummaries.length, 7);
  assert.deepEqual(result.periodSummary.nutrients.sugar_g, { knownTotal: 6, knownCount: 2, missingCount: 1, complete: false, provenanceCounts: { model_estimate: 3 } });
  assert.equal(result.periodSummary.nutrients.protein_g.knownTotal, null);
  assert.equal(result.dailySummaries[1].nutrients.sugar_g.knownTotal, null);
  assert.equal(result.dailySummaries[1].nutrients.sugar_g.complete, false);
  assert.equal(result.frequentFoods[0].title, 'Teh'); assert.equal(result.frequentFoods[0].entryCount, 2);
  assert.equal(result.frequentFoods[0].nutrients.sugar_g.knownTotal, 6);
  const empty = buildPattern([], snapshot, profile.timezone);
  assert.equal(empty.daysWithEntries, 0); assert.equal(empty.periodSummary.nutrients.sugar_g.knownTotal, null);
  assert.equal(empty.dailySummaries.every(day => day.entryCount === 0), true);
  const dst = patternWindow(new Date('2026-11-02T06:00:00Z'), 'America/New_York');
  assert.equal(dst.start.toISOString(), '2026-10-27T04:00:00.000Z'); assert.equal(dst.dates.length, 7);
  const fall = buildPattern([entry('Before midnight', '2026-11-01T03:59:00Z', 1), entry('After midnight', '2026-11-01T04:01:00Z', 2)], new Date('2026-11-02T06:00:00Z'), 'America/New_York');
  assert.equal(fall.dailySummaries.find(day => day.date === '2026-10-31').entryCount, 1);
  assert.equal(fall.dailySummaries.find(day => day.date === '2026-11-01').entryCount, 1);
  const ties = buildPattern(['Zulu', 'Beta', 'Alpha', 'Delta', 'Gamma', 'Extra'].map(name => entry(name, '2026-11-08T03:00:00Z', 1)), snapshot, profile.timezone);
  assert.deepEqual(ties.frequentFoods.map(food => food.title), ['Alpha', 'Beta', 'Delta', 'Extra', 'Gamma']);
  assert.throws(() => buildPattern(Array(1001).fill(data[0]), snapshot, profile.timezone), { code: 'PATTERN_LIMIT_EXCEEDED' });
});

test('assistant bounds context without dropping required evidence or inventing transmitted references', async () => {
  const ctx = assistantContext(); ctx.patternEvidence = buildPattern([], snapshot, profile.timezone);
  ctx.historyExamples = [{ title: 'x'.repeat(70000) }];
  assert.equal(boundAssistantContext(ctx).historyExamples.length, 0);
  ctx.references = [{ ...reference, text: 'x'.repeat(70000) }];
  const bounded = boundAssistantContext(ctx);
  assert.equal(bounded.references.length, 0); assert.deepEqual(bounded.patternEvidence, ctx.patternEvidence);
  assert.throws(() => boundAssistantContext({ ...ctx, profile: { priorities: ['x'.repeat(70000)] } }), { code: 'CONTEXT_TOO_LARGE' });
});

test('assistant reads owner context once, aggregates full window, and performs zero writes', async () => {
  process.env.DEEPSEEK_API_KEY = 'mock-only'; process.env.DEEPSEEK_BASE_URL = 'https://provider.test/v1';
  const prisma = require('../src/config/prisma'); const original = prisma.getPrismaClient;
  const counts = { profile: 0, retrieval: 0, pattern: 0, references: 0, dispatch: 0 };
  let large = false;
  const readOnly = table => new Proxy(table, { get(target, key) { if (!(key in target)) throw Error(`Unexpected DB operation: ${String(key)}`); return target[key]; } });
  prisma.getPrismaClient = () => readOnly({
    nutritionProfile: readOnly({ findUnique: async () => { counts.profile++; return profile; } }),
    foodEntry: readOnly({ findMany: async args => {
      assert.equal(args.where.userId, 'dummy');
      if (args.take === 1001) { counts.pattern++; assert.equal(args.where.consumedAt.gte.toISOString(), '2026-11-01T17:00:00.000Z');
        return Array(large ? 1001 : 8).fill(entry('Synthetic food', '2026-11-08T03:00:00Z', 2)); }
      counts.retrieval++; return [];
    } }),
    knowledgeChunk: readOnly({ findMany: async () => { counts.references++; return [{ ...reference, reviewedAt: snapshot }]; } }),
  });
  try {
    for (const mode of ['general', 'pattern']) {
      const result = await createAssistantMessage('dummy', readAssistantInput({ ...question(), mode }), async (_url, options) => {
        counts.dispatch++; const body = JSON.parse(options.body);
        assert.equal(body.max_tokens, 2048); assert.equal(body.messages.length, 2); assert.equal(body.messages[0].role, 'system');
        assert.equal(typeof body.messages[1].content, 'string'); assert.ok(!('tools' in body));
        const payload = JSON.parse(body.messages[1].content);
        assert.equal(payload.context.patternEvidence?.entryCount ?? null, mode === 'pattern' ? 8 : null);
        if (mode === 'general') assert.deepEqual(payload.context.historyExamples, []);
        for (const secret of ['private-name', 'private-email', 'private-password', 'heightCm', 'weightKg', '"age"']) assert.ok(!options.body.includes(secret), secret);
        return provider({ reply: 'Informasi ini berasal dari catatan yang tersedia dan masih perlu diperiksa.', citationIds: [reference.id] });
      }, snapshot);
      assert.equal(result.sources[0].sourceUrl, reference.sourceUrl); assert.ok(!('text' in result.sources[0]));
      assert.ok(!('profile' in result.contextSummary)); assert.equal('conversationId' in result, false);
    }
    assert.deepEqual(counts, { profile: 2, retrieval: 4, pattern: 1, references: 2, dispatch: 2 });
    large = true;
    await assert.rejects(createAssistantMessage('dummy', readAssistantInput({ ...question(), mode: 'pattern' }), async () => { assert.fail('large window dispatched'); }, snapshot), { code: 'PATTERN_LIMIT_EXCEEDED' });
    await assert.rejects(createAssistantMessage('dummy', readAssistantInput(question()), async () => { throw Error('outage'); }, snapshot), { code: 'PROVIDER_FAILED' });
  } finally { prisma.getPrismaClient = original; }
});

test('assistant validates output and citations and returns deterministic cold-start warnings', async () => {
  for (const example of [assistantGeneralExample, assistantPatternExample]) assert.ok(validateResponse(example), JSON.stringify(validateResponse.errors));
  assert.match(assistantPrompt(), /bahasa Indonesia sehari-hari/); assert.match(assistantPrompt(), /jangan menghitung total/);
  assert.match(assistantPrompt(), /diagnosis/); assert.match(assistantPrompt(), /data tidak tepercaya/);
  const ctx = assistantContext(); ctx.references = []; ctx.patternEvidence = buildPattern([], snapshot, profile.timezone);
  const input = readAssistantInput({ ...question(), mode: 'pattern' });
  const result = await analyzeAssistant(input, ctx, async () => provider());
  assert.ok(validateResponse(result), JSON.stringify(validateResponse.errors));
  assert.ok(result.warnings.some(text => text.includes('Belum ada catatan')));
  assert.ok(result.warnings.some(text => text.includes('Referensi'))); assert.deepEqual(result.sources, []);
  const partial = assistantContext(); partial.patternEvidence = buildPattern([entry('Test', '2026-11-08T03:00:00Z', 2)], snapshot, profile.timezone);
  assert.ok((await analyzeAssistant(input, partial, async () => provider())).warnings.some(text => text.includes('Sebagian nilai')));
  for (const value of [{ reply: '', citationIds: [] }, { reply: 'x'.repeat(4001), citationIds: [] },
    { reply: 'Jawaban', citationIds: ['unknown'] }, { reply: 'Jawaban', citationIds: [reference.id, reference.id] },
    { reply: '**Markdown**', citationIds: [] }, { reply: 'https://fake.test', citationIds: [] }, { reply: 'Jawaban', citationIds: [], extra: true }]) {
    let calls = 0;
    await assert.rejects(analyzeAssistant(input, ctx, async () => { calls++; return provider(value); }), { code: 'INVALID_PROVIDER_OUTPUT' });
    assert.equal(calls, 1);
  }
});

test('assistant transport rejects malformed, truncated, oversized and failed output without retry', async () => {
  for (const response of [new Response('not-json'), new Response('no', { status: 500 }),
    Response.json({ choices: [{ finish_reason: 'length' }] }), new Response('x'.repeat(65537))]) {
    let calls = 0;
    await assert.rejects(analyzeAssistant(readAssistantInput(question()), assistantContext(), async () => { calls++; return response; }), error => error.statusCode === 502);
    assert.equal(calls, 1);
  }
  const originalTimer = global.setTimeout;
  try {
    global.setTimeout = callback => { queueMicrotask(callback); return originalTimer(() => {}, 0); };
    await assert.rejects(analyzeAssistant(readAssistantInput(question()), assistantContext(), async (_url, options) => {
      assert.equal(options.signal.aborted, false);
      return new Promise((_resolve, reject) => options.signal.addEventListener('abort', () => reject(new Error('aborted'))));
    }), { code: 'PROVIDER_TIMEOUT', statusCode: 504 });
  } finally { global.setTimeout = originalTimer; }
  const originalKey = process.env.DEEPSEEK_API_KEY; delete process.env.DEEPSEEK_API_KEY;
  try { await assert.rejects(analyzeAssistant(readAssistantInput(question()), assistantContext(), async () => assert.fail('missing key dispatched')), { code: 'PROVIDER_NOT_CONFIGURED' }); }
  finally { process.env.DEEPSEEK_API_KEY = originalKey; }
});
