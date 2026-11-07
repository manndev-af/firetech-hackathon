const { test } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const http = require('node:http');
const sharp = require('sharp');
const express = require('express');
process.env.NODE_ENV = 'test';
process.env.SCANNER_USE_RAW_OCR = 'false';
require('ts-node/register');
const { compareUpload, readCompareInput, maxCompareBytes } = require('../src/middleware/compareUpload');
const { domainErrorHandler } = require('../src/utils/domainError');
const { scanSlot } = require('../src/middleware/scanUpload');

const meta = () => ({ a: { mode: 'food' }, b: { mode: 'label' } });
const png = () => sharp({ create: { width: 20, height: 30, channels: 3, background: '#fff' } }).png().toBuffer();
async function form(metadata = meta(), bytes) {
  bytes ??= await png();
  const body = new FormData();
  body.set('imageA', new Blob([bytes], { type: 'image/png' }), 'a.png');
  body.set('imageB', new Blob([bytes], { type: 'image/png' }), 'b.png');
  body.set('metadata', typeof metadata === 'string' ? metadata : JSON.stringify(metadata));
  return body;
}
async function serving(app, run) {
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  try { await run(`http://127.0.0.1:${server.address().port}`); }
  finally { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
}

test('comparison validates both uploads and metadata before analysis', async () => {
  let accepted = 0;
  const app = express();
  app.post('/', compareUpload, async (req, res) => {
    const input = await readCompareInput(req);
    accepted++;
    assert.equal(input.a.quantity, 1);
    assert.equal(input.basis, 'per_serving');
    assert.equal((await sharp(input.a.image).metadata()).width, 1600);
    res.json({ ok: true });
  });
  app.use(domainErrorHandler);
  await serving(app, async base => {
    assert.equal((await fetch(base, { method: 'POST', body: await form() })).status, 200);
    const invalid = [
      'invalid-json', {}, { ...meta(), userId: 'other' },
      { ...meta(), a: { mode: 'food', quantity: 0 } },
      { ...meta(), a: { mode: 'food', quantity: 10001 } },
      { ...meta(), a: { mode: 'food', quantity: 0.0000001 } },
      { ...meta(), a: { mode: 'food', quantity: '1' } },
      { ...meta(), a: { mode: 'food', description: 'x'.repeat(1001) } },
      { ...meta(), b: { mode: 'label', rawOcrText: 'x'.repeat(20001) } },
      { ...meta(), basis: 'ml' },
    ];
    for (const value of invalid)
      assert.equal((await fetch(base, { method: 'POST', body: await form(value) })).status, 400);
    for (const missing of ['imageA', 'imageB', 'metadata']) {
      const body = await form(); body.delete(missing);
      assert.equal((await fetch(base, { method: 'POST', body })).status, 400);
    }
    const extra = await form(); extra.set('ownerId', 'other');
    assert.equal((await fetch(base, { method: 'POST', body: extra })).status, 413);
    const duplicate = await form(); duplicate.append('imageA', new Blob([await png()], { type: 'image/png' }), 'other.png');
    assert.ok((await fetch(base, { method: 'POST', body: duplicate })).status >= 400);
    const repeatedMetadata = await form(); repeatedMetadata.append('metadata', '{}');
    assert.equal((await fetch(base, { method: 'POST', body: repeatedMetadata })).status, 413);
    assert.equal((await fetch(base, { method: 'POST', body: await form(meta(), Buffer.from('broken')) })).status, 415);
    const jpeg = await sharp(await png()).jpeg().toBuffer();
    assert.equal((await fetch(base, { method: 'POST', body: await form(meta(), jpeg) })).status, 415);
    const large = await sharp({ create: { width: 5000, height: 4001, channels: 3, background: '#fff' } }).png().toBuffer();
    assert.equal((await fetch(base, { method: 'POST', body: await form(meta(), large) })).status, 415);
    assert.equal((await fetch(base, { method: 'POST', body: await form(meta(), Buffer.alloc(5 * 1024 * 1024 + 1)) })).status, 413);
    process.env.SCANNER_USE_RAW_OCR = 'true';
    try {
      const response = await fetch(base, { method: 'POST', body: await form() });
      assert.equal(response.status, 400);
      assert.equal((await response.json()).data.code, 'OCR_REQUIRED');
    } finally { process.env.SCANNER_USE_RAW_OCR = 'false'; }
    assert.equal(accepted, 1);
  });
});

test('comparison bounds total bytes even without Content-Length', async () => {
  const app = express();
  app.post('/', compareUpload, (_req, res) => res.json({ ok: true }));
  app.use(domainErrorHandler);
  await serving(app, async base => {
    const response = await new Promise((resolve, reject) => {
      const request = http.request(base, { method: 'POST', headers: { 'Content-Type': 'multipart/form-data; boundary=bounded' } }, res => {
        let text = ''; res.on('data', chunk => text += chunk); res.on('end', () => resolve({ status: res.statusCode, text }));
      });
      request.on('error', reject);
      request.end(Buffer.alloc(maxCompareBytes + 1, 32));
    });
    assert.equal(response.status, 413);
    assert.equal(JSON.parse(response.text).data.code, 'UPLOAD_TOO_LARGE');
  });
});

const { nutrients } = require('../src/validation/nutrition');
const { analyzeComparison, buildComparison, createComparison } = require('../src/services/compare.service');
const { comparisonResponseSchema, comparisonExample } = require('../src/routes/compare.openapi');
const profile = { name: 'private-name', email: 'private-email', password: 'private-password', priorities: ['Gula', 'Protein', 'Keseimbangan'],
  preference: 'Masakan rumahan', eatingPattern: 'Fleksibel', prefersHalal: false, allergyStatus: 'unknown', allergies: [], otherAllergies: '', timezone: 'Asia/Jakarta' };
const context = { profile: { priorities: profile.priorities }, references: [], history: [] };
function option(mode = 'food') { return { mode, image: Buffer.from(mode), description: '', rawOcrText: '', quantity: 1 }; }
function analysis(mode = 'food', sugar = 12) {
  return { status: mode, identity: 'Synthetic fixture, not real food data',
    portion: { baseQuantity: 1, unitCode: 'porsi', displayLabel: '1 porsi (100 g)', basis: 'per_serving',
      originalServingText: mode === 'label' ? 'Takaran saji 100 g' : null, referenceWeightG: 100, referenceVolumeMl: null },
    nutrients: { ...Object.fromEntries(nutrients.map(key => [key, null])), sugar_g: sugar, protein_g: sugar / 3 },
    evidence: { ...Object.fromEntries(nutrients.map(key => [key, null])),
      ...(mode === 'label' ? { sugar_g: { origin: 'image', text: `Gula ${sugar} g` }, protein_g: { origin: 'image', text: `Protein ${sugar / 3} g` } } : {}) },
    warnings: ['Synthetic fixture; bukan pengukuran nyata.'], advantages: ['Bisa dipertimbangkan sesuai kebutuhanmu.'], tradeoffs: ['Cek lagi porsi dan kandungannya.'], citationIds: [] };
}
function pair(a = analysis(), b = analysis('food', 6)) {
  return { a, b, citationIds: [], summary: 'Bandingkan gula dan protein sesuai kebutuhanmu. Hasil ini masih perlu diperiksa.',
    ttsSummary: 'Ada pilihan dengan gula lebih sedikit, tapi proteinnya juga berbeda. Hasil ini masih perlu diperiksa.' };
}
const input = () => ({ a: option(), b: option(), basis: 'per_serving' });

test('comparison normalizes all bases deterministically and never replaces null with zero', () => {
  const result = buildComparison(pair(), input(), context);
  // OpenAPI 3.0 uses boolean exclusiveMinimum; AJV uses JSON Schema's numeric form.
  const jsonSchema = value => {
    if (Array.isArray(value)) return value.map(jsonSchema);
    if (!value || typeof value !== 'object') return value;
    const output = Object.fromEntries(Object.entries(value).map(([key, child]) => [key, jsonSchema(child)]));
    if (typeof output.exclusiveMinimum === 'boolean') {
      if (output.exclusiveMinimum) output.exclusiveMinimum = output.minimum;
      else delete output.exclusiveMinimum;
    }
    return output;
  };
  const validator = new (require('ajv'))({ strict: false }).compile(jsonSchema(comparisonResponseSchema));
  assert.ok(validator(result), JSON.stringify(validator.errors));
  assert.ok(validator(comparisonExample), JSON.stringify(validator.errors));
  assert.equal(result.differences.sugar_g, -6);
  assert.equal(result.differences.protein_g, -2);
  assert.equal(result.differences.sugar_g, comparisonExample.differences.sugar_g);
  assert.equal(result.differences.protein_g, comparisonExample.differences.protein_g);
  assert.equal(result.differences.fiber_g, null);
  assert.equal(result.comparisonBasis.status, 'common_basis');
  assert.deepEqual(result.prioritySignals.map(signal => signal.direction), ['lower', 'lower', 'unknown']);
  assert.equal(result.prioritySignals[1].preferredDirection, 'higher');
  assert.equal(result.prioritySignals[2].preferredDirection, null);
  const fractional = input(); fractional.a.quantity = 0.5;
  const fraction = buildComparison(pair(), fractional, context);
  assert.equal(fraction.differences.sugar_g, 0);
  assert.equal(fraction.comparisonBasis.status, 'as_portioned');
  for (const basis of ['per_100g', 'per_100ml']) {
    const request = input(); request.basis = basis; request.a.quantity = 7;
    const value = pair();
    value.a.portion.referenceWeightG = 200;
    value.b.portion.referenceWeightG = 200;
    if (basis === 'per_100ml') {
      value.a.portion.referenceVolumeMl = 200; value.b.portion.referenceVolumeMl = 200;
    }
    const normalized = buildComparison(value, request, context);
    assert.equal(normalized.comparedNutrients.a.sugar_g, 6);
    assert.equal(normalized.differences.sugar_g, -3);
    assert.equal(normalized.comparisonBasis.status, 'common_basis');
  }
  const grams = pair();
  Object.assign(grams.a.portion, { baseQuantity: 200, unitCode: 'g', basis: 'per_100g' });
  assert.throws(() => buildComparison(grams, input(), context), { code: 'INVALID_PORTION' });
  const direct = pair(); Object.assign(direct.a.portion, { baseQuantity: 100, unitCode: 'g', basis: 'per_100g' });
  const per100 = input(); per100.basis = 'per_100g';
  assert.equal(buildComparison(direct, per100, context).comparedNutrients.a.sugar_g, 12);
  const absent = pair(); absent.a.portion.referenceWeightG = null;
  const missing = buildComparison(absent, per100, context);
  assert.equal(missing.comparisonBasis.status, 'unavailable');
  assert.ok(Object.values(missing.differences).every(value => value === null));
  assert.ok(Object.values(missing.comparedNutrients.b).every(value => value === null));
  assert.equal(missing.items.a.baseNutrients.sugar_g, 12);
  const incompatible = input(); incompatible.basis = 'per_100ml';
  assert.equal(buildComparison(pair(), incompatible, context).comparisonBasis.status, 'unavailable');
  const zero = pair(); zero.a.nutrients.protein_g = 0; zero.b.nutrients.protein_g = 0;
  assert.equal(buildComparison(zero, input(), context).differences.protein_g, 0);
  zero.b.nutrients.protein_g = null;
  assert.equal(buildComparison(zero, input(), context).differences.protein_g, null);
});

test('pair validation preserves evidence, identifies invalid A/B and replaces unsupported narrative', () => {
  const request = input(); request.a.mode = 'label';
  const value = pair(analysis('label'));
  value.a.evidence.sugar_g.text = 'Gula 90 g';
  const rejected = buildComparison(value, request, context);
  assert.equal(rejected.items.a.baseNutrients.sugar_g, null);
  assert.equal(rejected.differences.sugar_g, null);
  assert.equal(rejected.ttsSummarySource, 'template');
  assert.match(rejected.summary, /belum bisa dicocokkan/);
  process.env.SCANNER_USE_RAW_OCR = 'true';
  try {
    const correction = pair(analysis('label'));
    request.a.rawOcrText = 'Gula 12q\nProtein 4 g';
    assert.equal(buildComparison(structuredClone(correction), request, context).items.a.baseNutrients.sugar_g, 12);
    correction.a.evidence.sugar_g.origin = 'ocr';
    assert.equal(buildComparison(correction, request, context).items.a.baseNutrients.sugar_g, null);
    const conflict = pair(analysis('label'));
    request.a.rawOcrText = 'Gula 90 g\nProtein 4 g';
    assert.equal(buildComparison(conflict, request, context).items.a.baseNutrients.sugar_g, null);
  } finally { process.env.SCANNER_USE_RAW_OCR = 'false'; }
  for (const key of ['a', 'b']) {
    const uncertain = pair(); uncertain[key] = { status: 'uncertain' };
    assert.throws(() => buildComparison(uncertain, input(), context), error => error.code === 'RESCAN_REQUIRED' && error.message.includes(key.toUpperCase()));
  }
  assert.throws(() => buildComparison({ ...pair(), extra: 'ignored?' }, input(), context), { code: 'INVALID_PROVIDER_OUTPUT' });
  assert.throws(() => buildComparison({ ...pair(), citationIds: ['invented'] }, input(), context), { code: 'INVALID_PROVIDER_OUTPUT' });
  for (const text of ['Gula 6 g lebih rendah. Periksa lagi.', 'Makanan ini menyembuhkan penyakit. Periksa lagi.', '**Pilihan bagus**. Periksa lagi.', 'kata '.repeat(100), null]) {
    const response = buildComparison({ ...pair(), summary: text, ttsSummary: text }, input(), context);
    assert.equal(response.ttsSummarySource, 'template');
    assert.ok(response.ttsSummary.length <= 450 && response.ttsSummary.split(/\s+/).length <= 60);
    assert.equal(response.ttsSummary.match(/[^.!?]+[.!?]+/g).length, 2);
  }
});

test('one provider dispatch contains two labeled images for food, label and mixed pairs', async () => {
  process.env.DEEPSEEK_API_KEY = 'mock-only'; process.env.DEEPSEEK_BASE_URL = 'https://provider.test/v1';
  for (const modes of [['food', 'food'], ['label', 'label'], ['food', 'label']]) {
    for (const rawOcr of ['false', 'true']) {
      process.env.SCANNER_USE_RAW_OCR = rawOcr;
      const request = input(); request.a = option(modes[0]); request.b = option(modes[1]);
      request.a.rawOcrText = 'Gula 12 g\nProtein 4 g'; request.b.rawOcrText = 'Gula 6 g\nProtein 2 g';
      let calls = 0;
      const result = await analyzeComparison(request, context, async (_url, options) => {
        calls++;
        const body = JSON.parse(options.body);
        assert.equal(body.max_tokens, 8192);
        const content = body.messages[1].content;
        assert.equal(content.filter(item => item.type === 'image_url').length, 2);
        assert.equal(content[1].text, 'PILIHAN A'); assert.equal(content[3].text, 'PILIHAN B');
        const metadata = JSON.parse(content[0].text);
        assert.equal('rawOcrText' in metadata.a, rawOcr === 'true');
        return Response.json({ choices: [{ finish_reason: 'stop', message: { content: JSON.stringify(pair(analysis(modes[0]), analysis(modes[1], 6))) } }] });
      });
      assert.equal(calls, 1); assert.equal(result.items.a.mode, modes[0]); assert.equal(result.items.b.mode, modes[1]);
      assert.equal(result.differences.sugar_g, -6);
    }
  }
  process.env.SCANNER_USE_RAW_OCR = 'false';
  let failed = 0;
  await assert.rejects(analyzeComparison(input(), context, async () => { failed++; return Response.json({ choices: [{ finish_reason: 'length' }] }); }), { code: 'INVALID_PROVIDER_OUTPUT' });
  assert.equal(failed, 1);
});

test('comparison reads personalization once, never writes and excludes identity from provider', async () => {
  const prisma = require('../src/config/prisma');
  const original = prisma.getPrismaClient;
  const reads = { profile: 0, entries: 0, references: 0 };
  const readOnly = table => new Proxy(table, { get(target, key) { if (!(key in target)) throw Error(`Database write or unexpected operation: ${String(key)}`); return target[key]; } });
  prisma.getPrismaClient = () => readOnly({
    nutritionProfile: readOnly({ findUnique: async () => { reads.profile++; return profile; } }),
    foodEntry: readOnly({ findMany: async () => { reads.entries++; return []; } }),
    knowledgeChunk: readOnly({ findMany: async () => { reads.references++; return []; } }),
  });
  try {
    const result = await createComparison('dummy', input(), async (_url, options) => {
      for (const secret of ['private-name', 'private-email', 'private-password']) assert.ok(!options.body.includes(secret));
      return Response.json({ choices: [{ finish_reason: 'stop', message: { content: JSON.stringify(pair()) } }] });
    });
    assert.equal(result.differences.sugar_g, -6);
    assert.deepEqual(reads, { profile: 1, entries: 2, references: 1 });
    await assert.rejects(createComparison('dummy', input(), async () => { throw Error('mock outage'); }), { code: 'PROVIDER_FAILED' });
    assert.deepEqual(reads, { profile: 2, entries: 4, references: 2 });
  } finally { prisma.getPrismaClient = original; }
});

test('registered HTTP route uses dummy owner, returns transient results and never writes', async () => {
  process.env.ENABLE_DEMO_USER = 'true'; process.env.DEMO_USER_EMAIL = 'demo@example.test';
  const prisma = require('../src/config/prisma');
  const original = prisma.getPrismaClient;
  const nativeFetch = global.fetch;
  let calls = 0;
  let fail = false;
  const readOnly = table => new Proxy(table, { get(target, key) {
    if (!(key in target)) throw Error(`Unexpected database operation: ${String(key)}`);
    return target[key];
  } });
  prisma.getPrismaClient = () => readOnly({
    user: readOnly({ findUnique: async () => ({ id: 'dummy' }) }),
    nutritionProfile: readOnly({ findUnique: async () => profile }),
    foodEntry: readOnly({ findMany: async () => [] }),
    knowledgeChunk: readOnly({ findMany: async () => [] }),
  });
  global.fetch = async (_url, options) => {
    calls++;
    assert.equal(JSON.parse(options.body).messages[1].content.filter(part => part.type === 'image_url').length, 2);
    if (fail) throw Error('provider unavailable');
    return Response.json({ choices: [{ finish_reason: 'stop', message: { content: JSON.stringify(pair(analysis(), analysis('label', 6))) } }] });
  };
  try {
    const { createApp } = require('../src/app');
    const { config } = require('../src/config/config');
    await serving(createApp(), async base => {
      const url = `${base}${config.apiPrefix}/v1/comparisons`;
      const success = await nativeFetch(url, { method: 'POST', body: await form() });
      assert.equal(success.status, 200);
      const response = await success.json();
      assert.equal(response.success, true);
      assert.equal(response.data.differences.sugar_g, -6);
      assert.ok(!('id' in response.data) && !('comparisonId' in response.data));
      assert.equal(calls, 1);
      assert.equal((await nativeFetch(url, { method: 'POST', body: await form('{}') })).status, 400);
      assert.equal(calls, 1);
      assert.equal((await nativeFetch(url, { method: 'POST', headers: { 'X-User-Id': 'other' }, body: await form() })).status, 400);
      assert.equal(calls, 1);
      fail = true;
      const failure = await nativeFetch(url, { method: 'POST', body: await form() });
      assert.equal(failure.status, 502);
      assert.equal((await failure.json()).data.code, 'PROVIDER_FAILED');
      assert.equal(calls, 2);
    });
  } finally { prisma.getPrismaClient = original; global.fetch = nativeFetch; }
});

test('scanner and comparison share two slots; disconnect holds slot until operation finishes', async () => {
  const compareService = require('../src/services/compare.service');
  const scanService = require('../src/services/scan.service');
  const originalCompare = compareService.createComparison;
  const originalScan = scanService.createScan;
  const pending = [];
  const started = [];
  const waitFor = async predicate => {
    const deadline = Date.now() + 5000;
    while (!predicate()) {
      assert.ok(Date.now() < deadline, 'operation did not reach expected state');
      await new Promise(resolve => setTimeout(resolve, 10));
    }
  };
  const hold = kind => new Promise(resolve => { started.push(kind); pending.push(resolve); });
  compareService.createComparison = async () => { await hold('compare'); return comparisonExample; };
  scanService.createScan = async () => { await hold('scanner'); return { entry: { id: 'existing-scanner-contract' }, replay: false }; };
  const app = express();
  app.use((_req, res, next) => { res.locals.userId = 'dummy'; next(); });
  app.use('/compare', require('../src/routes/compare.routes').default);
  app.use('/scan', require('../src/routes/scanner.routes').default);
  app.use(domainErrorHandler);
  try {
    await serving(app, async base => {
      const scanBody = new FormData();
      scanBody.set('image', new Blob([await png()], { type: 'image/png' }), 'scan.png'); scanBody.set('mode', 'food');
      const scanner = fetch(`${base}/scan`, { method: 'POST', headers: { 'Idempotency-Key': '12345678-1234-4123-8123-123456789abc' }, body: scanBody });
      await waitFor(() => started.length === 1);
      const controller = new AbortController();
      const comparison = fetch(`${base}/compare`, { method: 'POST', body: await form(), signal: controller.signal })
        .then(() => assert.fail('aborted request returned a result'), error => assert.equal(error.name, 'AbortError'));
      await waitFor(() => started.length === 2);
      assert.deepEqual(started, ['scanner', 'compare']);
      controller.abort(); await comparison;
      const busy = await fetch(`${base}/compare`, { method: 'POST', body: await form() });
      assert.equal(busy.status, 429); assert.equal((await busy.json()).data.code, 'SCAN_BUSY');
      assert.equal(started.length, 2);
      pending[1]();
      await new Promise(resolve => setTimeout(resolve, 20));
      const next = fetch(`${base}/compare`, { method: 'POST', body: await form() });
      await waitFor(() => started.length === 3);
      pending[2](); assert.equal((await next).status, 200);
      pending[0](); assert.equal((await scanner).status, 201);
      assert.equal(started.length, 3); // No retry after disconnect.
    });
  } finally {
    pending.forEach(resolve => resolve());
    compareService.createComparison = originalCompare; scanService.createScan = originalScan;
  }
});
