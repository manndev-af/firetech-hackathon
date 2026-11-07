const { test } = require('node:test');
const assert = require('node:assert/strict');
const sharp = require('sharp');
require('ts-node/register');
const { readScanInput } = require('../src/middleware/scanUpload');

test('food and label uploads become 1600-square JPEGs without cropping', async () => {
  for (const [mode, width, height] of [['food', 1200, 600], ['label', 200, 400]]) {
    const buffer = await sharp({ create: { width, height, channels: 3, background: '#ff0000' } }).png().toBuffer();
    const result = await readScanInput({
      get: () => '108ca11c-e9ae-4f66-b671-5689d998ff19',
      body: { mode, ...(mode === 'label' ? { rawOcrText: 'Takaran saji 100 g' } : {}) },
      file: { buffer, size: buffer.length, mimetype: 'image/png' },
    });
    const metadata = await sharp(result.image).metadata();
    assert.equal(metadata.width, 1600);
    assert.equal(metadata.height, 1600);
    assert.equal(metadata.format, 'jpeg');
    assert.deepEqual(result.original, buffer);
    const { data, info } = await sharp(result.image).raw().toBuffer({ resolveWithObject: true });
    const pixel = (x, y) => [...data.subarray((y * info.width + x) * info.channels, (y * info.width + x) * info.channels + 3)];
    assert.ok(pixel(0, 0).every(channel => channel > 245));
    assert.ok(pixel(800, 800)[1] < 10);
    // The red content must fill the long axis and preserve the 2:1 ratio.
    const inside = width > height ? pixel(10, 410) : pixel(410, 10);
    const outside = width > height ? pixel(800, 380) : pixel(380, 800);
    assert.ok(inside[0] > 245 && inside[1] < 10);
    assert.ok(outside.every(channel => channel > 245));
    if (mode === 'label') assert.equal(result.rawOcrText, 'Takaran saji 100 g');
  }
});

test('label OCR is optional while disabled and required when reenabled', async () => {
  const buffer = await sharp({ create: { width: 20, height: 20, channels: 3, background: '#ffffff' } }).png().toBuffer();
  const req = { get: () => '108ca11c-e9ae-4f66-b671-5689d998ff19', body: { mode: 'label' }, file: { buffer, size: buffer.length, mimetype: 'image/png' } };
  const previous = process.env.SCANNER_USE_RAW_OCR;
  try {
    delete process.env.SCANNER_USE_RAW_OCR;
    assert.equal((await readScanInput(req)).rawOcrText, '');
    process.env.SCANNER_USE_RAW_OCR = 'true';
    await assert.rejects(readScanInput(req), { code: 'OCR_REQUIRED' });
    req.body.rawOcrText = 'Energi 100 kkal';
    assert.equal((await readScanInput(req)).rawOcrText, 'Energi 100 kkal');
  } finally {
    if (previous === undefined) delete process.env.SCANNER_USE_RAW_OCR;
    else process.env.SCANNER_USE_RAW_OCR = previous;
  }
});
