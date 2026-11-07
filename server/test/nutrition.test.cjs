const { test } = require('node:test');
const assert = require('node:assert/strict');
process.env.NODE_ENV = 'test';
require('ts-node/register');
const { Prisma } = require('../src/generated/prisma/client');
const { mergeProfile } = require('../src/services/profile.service');
const { dayBounds, totals, summarize, serializeEntry } = require('../src/services/journal.service');
const { nutrients, priorities, allergens, preferences, patterns } = require('../src/validation/nutrition');
const { validateAnalysis, spokenSummary, callDeepSeek } = require('../src/services/deepseek.service');

const profile = { name: '', age: null, heightCm: null, weightKg: null, priorities: [], allergies: [], otherAllergies: '', allergyStatus: 'unknown', prefersHalal: false, audioAnalysisEnabled: false, preference: null, eatingPattern: null, timezone: 'Asia/Jakarta' };
function fixture(mode = 'food') {
  return { status: mode, identity: 'Synthetic test fixture',
    portion: { baseQuantity: 1, unitCode: 'porsi', displayLabel: '1 porsi', basis: 'per_serving', originalServingText: mode === 'label' ? 'Takaran saji 100 g' : null, referenceWeightG: 100, referenceVolumeMl: null },
    nutrients: Object.fromEntries(nutrients.map(key => [key, null])), evidence: Object.fromEntries(nutrients.map(key => [key, null])),
    warnings: ['Data sintetis untuk tes.'], advantages: [], tradeoffs: [], citationIds: [],
    ttsSummary: 'Nilai nutrisi ini masih berupa perkiraan. Periksa porsi makanan yang tercatat.',
  };
}

test('profile matches Flutter fields and partial-save rules', () => {
  assert.deepEqual(mergeProfile(profile, { name: ' Naya ', age: 21 }), { name: 'Naya', age: 21 });
  assert.deepEqual(mergeProfile(profile, { audioAnalysisEnabled: true }), { audioAnalysisEnabled: true });
  for (const input of [{ priorities: [] }, { name: 'x'.repeat(61) }, { age: 1.5 }, { age: 121 }, { heightCm: 0 }, { heightCm: 301 }, { weightKg: 701 }, { weightKg: NaN }, { userId: 'other' }, { timezone: 'not/a/zone' }, { name: null }]) assert.throws(() => mergeProfile(profile, input));
  const complete = { name: 'Naya', age: 22, heightCm: 165.5, weightKg: 58.25, preference: 'Masakan rumahan', priorities: [...priorities], eatingPattern: 'Vegetarian', prefersHalal: true, allergyStatus: 'listed', allergies: [...allergens], otherAllergies: ' Wijen ', audioAnalysisEnabled: true, timezone: 'Asia/Jakarta' };
  assert.equal(mergeProfile(profile, complete).otherAllergies, 'Wijen');
  assert.throws(() => mergeProfile(profile, { priorities: ['Gula', 'Gula'] }));
  assert.throws(() => mergeProfile(profile, { priorities: ['Gula'], allergies: ['Unknown'] }));
  assert.throws(() => mergeProfile(profile, { priorities: ['Gula'], allergyStatus: 'listed' }));
  assert.equal(mergeProfile(profile, { priorities: ['Gula'], allergyStatus: 'listed', otherAllergies: 'Wijen' }).otherAllergies, 'Wijen');
  const previous = { ...profile, priorities: ['Gula'], allergyStatus: 'listed', allergies: ['Susu'], otherAllergies: 'Wijen' };
  assert.deepEqual(mergeProfile(previous, { allergyStatus: 'noneKnown' }), { allergyStatus: 'noneKnown', allergies: [], otherAllergies: '' });
  assert.throws(() => mergeProfile(previous, { allergyStatus: 'unknown', allergies: ['Susu'] }));
  assert.deepEqual(mergeProfile(previous, { age: null, heightCm: null, weightKg: null }), { age: null, heightCm: null, weightKg: null });
  for (const preference of preferences) assert.equal(mergeProfile(previous, { preference }).preference, preference);
  for (const eatingPattern of patterns) assert.equal(mergeProfile(previous, { eatingPattern }).eatingPattern, eatingPattern);
  for (const input of [{ preference: 'Invalid' }, { eatingPattern: 'Invalid' }, { prefersHalal: 'true' }, { audioAnalysisEnabled: 1 }, { allergies: ['Susu', 'Susu'] }, { otherAllergies: 'x'.repeat(121) }, { heightCm: -1 }, { weightKg: 0 }, { age: 0 }]) assert.throws(() => mergeProfile(previous, input));
});

test('day bounds preserve local midnight and DST', () => {
  const jakarta = dayBounds('2026-11-07', 'Asia/Jakarta');
  assert.equal(jakarta.start.toISOString(), '2026-11-06T17:00:00.000Z');
  assert.equal(jakarta.end - jakarta.start, 86400000);
  const spring = dayBounds('2026-03-08', 'America/New_York');
  const autumn = dayBounds('2026-11-01', 'America/New_York');
  assert.equal(spring.end - spring.start, 23 * 3600000);
  assert.equal(autumn.end - autumn.start, 25 * 3600000);
  assert.throws(() => dayBounds('2026-02-30', 'Asia/Jakarta'));
});

test('portion arithmetic preserves null, real zero, fractions and original basis', () => {
  const entry = { ...Object.fromEntries(nutrients.map(key => [key, null])), baseQuantity: new Prisma.Decimal(1), quantity: new Prisma.Decimal(2), calories_kcal: new Prisma.Decimal('12.34'), protein_g: new Prisma.Decimal(0), provenance: 'model_estimate' };
  assert.equal(totals(entry).calories_kcal, 24.68);
  assert.equal(totals(entry).protein_g, 0);
  assert.equal(totals(entry).sugar_g, null);
  entry.quantity = new Prisma.Decimal('0.5');
  assert.equal(totals(entry).calories_kcal, 6.17);
  entry.quantity = new Prisma.Decimal(1);
  assert.equal(totals(entry).calories_kcal, 12.34);
  const result = summarize([entry]);
  assert.equal(result.nutrients.sugar_g.knownTotal, null);
  assert.equal(result.nutrients.sugar_g.missingCount, 1);
  assert.equal(result.nutrients.protein_g.knownTotal, 0);
  assert.equal(summarize([]).entryCount, 0);
});

test('analysis rejects unsupported structure and keeps label gaps unknown', () => {
  assert.throws(() => validateAnalysis({ status: 'not_food' }, 'food', '', []), { code: 'RESCAN_REQUIRED' });
  assert.throws(() => validateAnalysis({ status: 'uncertain' }, 'food', '', []), { code: 'RESCAN_REQUIRED' });
  assert.equal(validateAnalysis(fixture(), 'food', '', []).portion.basisSource, 'model_estimate');
  for (const mutate of [a => a.nutrients.protein_g = -1, a => a.portion.unitCode = 'semangkuk', a => a.citationIds = ['invented'], a => a.portion.baseQuantity = Infinity, a => a.advantages = ['Menyembuhkan penyakit'], a => a.userId = 'injected']) {
    const input = fixture(); mutate(input); assert.throws(() => validateAnalysis(input, 'food', '', []));
  }
  const label = fixture('label');
  label.nutrients.protein_g = 5;
  label.evidence.protein_g = { origin: 'ocr', text: 'Protein 5 g' };
  assert.equal(validateAnalysis(label, 'label', 'Protein 5 g', []).nutrients.protein_g, 5);
  assert.equal(validateAnalysis(label, 'label', 'Karbohidrat 1 g', []).nutrients.protein_g, null);
  for (const [value, evidence, raw] of [
    [8, 'Protein 5 g', 'Protein 5 g'],
    [5, 'Protein 5 mg', 'Protein 5 mg'],
    [5, 'Protein 5 g', 'Protein 7 g'],
    [5, 'Protein 5 g 10 g', 'Protein 5 g 10 g'],
    [5, 'Gula 5 g', 'Gula 5 g'],
  ]) {
    const conflict = fixture('label');
    conflict.nutrients.protein_g = value;
    conflict.evidence.protein_g = { origin: 'image', text: evidence };
    assert.equal(validateAnalysis(conflict, 'label', raw, []).nutrients.protein_g, null);
  }
  label.portion.unitCode = 'botol'; label.portion.referenceWeightG = null;
  assert.throws(() => validateAnalysis(label, 'label', '', []), { code: 'RESCAN_REQUIRED' });
  label.portion.referenceVolumeMl = 500;
  assert.throws(() => validateAnalysis(label, 'label', '', []), { code: 'RESCAN_REQUIRED' });
  label.portion.originalServingText = 'Takaran saji 1 botol (500 ml)';
  assert.equal(validateAnalysis(label, 'label', 'Protein 5 g', []).portion.unitCode, 'botol');
});

test('speech remains concise with local fallback only', () => {
  assert.equal(spokenSummary(fixture().ttsSummary, true, 'food').ttsSummarySource, 'model');
  for (const value of [null, '', 'word '.repeat(61), 'Protein 5 gram. Makan sekarang.', '**Bagus**. Aman.', 'Makanan bebas alergen. Pasti aman.']) {
    const result = spokenSummary(value, true, 'food');
    assert.equal(result.ttsSummarySource, 'template');
    assert.ok(result.ttsSummary.length <= 450);
  }
  const input = fixture(); delete input.ttsSummary;
  assert.equal(validateAnalysis(input, 'food', '', []).ttsSummarySource, 'template');
  input.ttsSummary = 'Makanan tinggi protein. Perkiraan ini perlu diperiksa.';
  assert.equal(validateAnalysis(input, 'food', '', []).ttsSummarySource, 'template');
});

test('personalized pros/cons are exposed and reused by concise fallback speech', () => {
  const input = fixture();
  input.nutrients.protein_g = 5;
  input.advantages = ['Protein membantu memenuhi fokus protein Anda.'];
  input.tradeoffs = ['Gula belum diketahui sehingga fokus gula belum dapat dinilai.'];
  input.ttsSummary = '**invalid summary**';
  const analysis = validateAnalysis(input, 'food', '', [], ['Gula', 'Protein']);
  assert.equal(analysis.ttsSummarySource, 'template');
  assert.match(analysis.ttsSummary, /memperhatikan gula dan protein/);
  assert.match(analysis.ttsSummary, /Protein membantu/);
  assert.match(analysis.ttsSummary, /Gula belum diketahui/);
  assert.ok(analysis.ttsSummary.length <= 450 && analysis.ttsSummary.split(/\s+/).length <= 60);
  const entry = { ...Object.fromEntries(nutrients.map(key => [key, null])), quantity: new Prisma.Decimal(1), baseQuantity: new Prisma.Decimal(1), analysis };
  const serialized = serializeEntry(entry);
  assert.deepEqual(serialized.pros, analysis.advantages);
  assert.deepEqual(serialized.cons, analysis.tradeoffs);
  entry.quantity = new Prisma.Decimal(2);
  assert.equal(serializeEntry(entry).ttsSummary, serialized.ttsSummary);
  const limited = validateAnalysis(fixture(), 'food', '', []);
  assert.match(limited.advantages[0], /Data belum cukup/);
  assert.match(limited.tradeoffs[0], /Data belum cukup/);
  const tooLong = fixture(); tooLong.advantages = ['kata '.repeat(90)]; delete tooLong.ttsSummary;
  assert.ok(validateAnalysis(tooLong, 'food', '', []).ttsSummary.length <= 450);
});

test('DeepSeek transport receives image and OCR once and rejects bad responses without retry', async () => {
  process.env.SCANNER_USE_RAW_OCR = 'true';
  process.env.DEEPSEEK_API_KEY = 'test-only-not-real';
  process.env.DEEPSEEK_BASE_URL = 'https://deepseek.test/v1/';
  const context = { references: [], profile: { priorities: ['Gula'] } };
  let calls = 0;
  const transport = async (url, options) => {
    calls++;
    assert.equal(url, 'https://deepseek.test/v1/chat/completions');
    const body = JSON.parse(options.body);
    assert.equal(body.messages[1].content[0].type, 'text');
    assert.match(body.messages[1].content[0].text, /rawOcrText/);
    assert.match(body.messages[1].content[1].image_url.url, /^data:image\/jpeg;base64,/);
    assert.match(body.messages[0].content, /ttsSummary/);
    assert.match(body.messages[0].content, /context.profile.priorities/);
    assert.match(body.messages[0].content, /Ringkas advantages dan tradeoffs/);
    return Response.json({ choices: [{ finish_reason: 'stop', message: { content: JSON.stringify(fixture('label')) } }] });
  };
  const input = { mode: 'label', image: Buffer.from('synthetic'), description: '', rawOcrText: 'Takaran saji 100 g' };
  await callDeepSeek(input, context, transport);
  assert.equal(calls, 1);
  await assert.rejects(callDeepSeek(input, context, async () => { calls++; return Response.json({ choices: [{ finish_reason: 'length' }] }); }));
  assert.equal(calls, 2);
  await assert.rejects(callDeepSeek(input, context, async () => { throw new DOMException('Mock abort', 'AbortError'); }));
  await assert.rejects(callDeepSeek(input, context, async () => Response.json({ choices: [{ finish_reason: 'stop', message: { content: '{invalid' } }] })));
  await assert.rejects(callDeepSeek(input, context, async () => new Response('x'.repeat(128 * 1024 + 1))), { code: 'PROVIDER_RESPONSE_LIMIT' });
  const schedule = global.setTimeout;
  global.setTimeout = (callback, ms, ...args) => schedule(callback, ms === 45000 ? 0 : ms, ...args);
  try {
    await assert.rejects(callDeepSeek(input, context, async (_url, options) => new Promise((_resolve, reject) => {
      options.signal.addEventListener('abort', () => reject(new DOMException('Mock timeout', 'AbortError')), { once: true });
    })), { code: 'PROVIDER_TIMEOUT', statusCode: 504 });
  } finally { global.setTimeout = schedule; }
  const before = calls;
  for (const baseUrl of ['', 'not-a-url', 'file:///tmp/provider', 'https://user:password@deepseek.test', 'https://deepseek.test?query=1', 'https://deepseek.test#fragment']) {
    process.env.DEEPSEEK_BASE_URL = baseUrl;
    await assert.rejects(callDeepSeek(input, context, transport), { code: 'PROVIDER_NOT_CONFIGURED', statusCode: 503 });
  }
  assert.equal(calls, before);
});

test('raw OCR switch omits OCR from provider and evidence validation until reenabled', async () => {
  process.env.DEEPSEEK_API_KEY = 'mock-only';
  process.env.DEEPSEEK_BASE_URL = 'https://deepseek.test';
  const context = { references: [], profile: { priorities: [] } };
  const input = { mode: 'label', image: Buffer.from('synthetic'), description: '', rawOcrText: 'Energi 200 kkal' };
  const previous = process.env.SCANNER_USE_RAW_OCR;
  try {
    for (const enabled of [undefined, 'false', 'true']) {
      if (enabled === undefined) delete process.env.SCANNER_USE_RAW_OCR;
      else process.env.SCANNER_USE_RAW_OCR = enabled;
      let calls = 0;
      const result = await callDeepSeek(input, context, async (_url, options) => {
        calls++;
        const payload = JSON.parse(options.body);
        const text = JSON.parse(payload.messages[1].content[0].text);
        assert.equal('rawOcrText' in text, enabled === 'true');
        assert.ok(payload.messages[1].content[1].image_url.url.startsWith('data:image/jpeg;base64,'));
        if (enabled !== 'true') assert.match(payload.messages[0].content, /origin image, bukan ocr/);
        const analysis = fixture('label');
        analysis.nutrients.calories_kcal = 100;
        analysis.evidence.calories_kcal = { origin: 'image', text: 'Energi 100 kkal' };
        return Response.json({ choices: [{ finish_reason: 'stop', message: { content: JSON.stringify(analysis) } }] });
      });
      assert.equal(calls, 1);
      assert.equal(result.nutrients.calories_kcal, enabled === 'true' ? null : 100);
    }
  } finally {
    if (previous === undefined) delete process.env.SCANNER_USE_RAW_OCR;
    else process.env.SCANNER_USE_RAW_OCR = previous;
  }
});

// Transcription of the supplied photo, not output from a device OCR run.
const sampleRows = {
  calories_kcal: ['Energi Total / Total Energy 100 kkal', 100],
  protein_g: ['Protein  0g  0%', 0],
  total_fat_g: ['Lemak Total / Total Fat 5 g', 5],
  saturated_fat_g: ['LemakJenuh 2 g', 2],
  carbohydrates_g: ['Karbohidrat Total 14 g', 14],
  sugar_g: ['Gula 1 g', 1],
  sodium_mg: ['Natrium 210 mg', 210],
};
test('sample label keeps total energy separate and counts servings, not grams', () => {
  const raw = ['Takaran saji 20 g', ...Object.values(sampleRows).map(([row]) => row),
    'Energi dari Lemak 45 kkal', 'Kebutuhan energi 2150 kkal'].join('\n');
  for (const origin of ['image', 'ocr']) {
    const input = fixture('label');
    Object.assign(input.portion, { baseQuantity: 20, unitCode: 'g', referenceWeightG: 20, originalServingText: 'Takaran saji 20 g' });
    for (const [key, [row, amount]] of Object.entries(sampleRows)) {
      input.nutrients[key] = amount;
      input.evidence[key] = { origin, text: row.replace(/\s+/g, ' ').replace('0g', '0 g') };
    }
    const result = validateAnalysis(input, 'label', raw, []);
    for (const [key, [, amount]] of Object.entries(sampleRows)) assert.equal(result.nutrients[key], amount, key);
    assert.equal(result.nutrients.fiber_g, null);
    assert.equal(result.portion.baseQuantity, 1);
    assert.equal(result.portion.unitCode, 'porsi');
    assert.equal(result.portion.referenceWeightG, 20);
    for (const quantity of [0.5, 1, 2]) {
      assert.equal(totals({ ...result.nutrients, baseQuantity: result.portion.baseQuantity, quantity }).calories_kcal, 100 * quantity);
    }
  }
});
test('volume servings normalize while conflicts invalidate insights and speech', () => {
  const input = fixture('label');
  Object.assign(input.portion, { baseQuantity: 200, unitCode: 'ml', referenceWeightG: null, referenceVolumeMl: 200, originalServingText: 'Takaran saji 200 ml' });
  input.nutrients.calories_kcal = 180;
  input.evidence.calories_kcal = { origin: 'image', text: 'Energi Total 180 kkal' };
  assert.equal(validateAnalysis(structuredClone(input), 'label', 'Energi dari Lemak 60 kkal', []).nutrients.calories_kcal, 180);
  const result = validateAnalysis(input, 'label', 'Energi Total 90 kkal', []);
  assert.equal(result.portion.baseQuantity, 1);
  assert.equal(result.portion.referenceVolumeMl, 200);
  assert.equal(result.nutrients.calories_kcal, null);
  assert.match(result.advantages[0], /belum bisa disimpulkan/);
  assert.equal(result.ttsSummarySource, 'template');
});
