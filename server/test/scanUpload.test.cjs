const { test } = require('node:test');
const assert = require('node:assert/strict');
const sharp = require('sharp');
require('ts-node/register');
const { readScanInput } = require('../src/middleware/scanUpload');

test('food and label uploads become 544-square JPEGs without cropping', async () => {
  for (const [mode, width, height] of [['food', 1200, 600], ['label', 200, 400]]) {
    const buffer = await sharp({ create: { width, height, channels: 3, background: '#ff0000' } }).png().toBuffer();
    const result = await readScanInput({
      get: () => '108ca11c-e9ae-4f66-b671-5689d998ff19',
      body: { mode, ...(mode === 'label' ? { rawOcrText: 'Takaran saji 100 g' } : {}) },
      file: { buffer, size: buffer.length, mimetype: 'image/png' },
    });
    const metadata = await sharp(result.image).metadata();
    assert.equal(metadata.width, 544);
    assert.equal(metadata.height, 544);
    assert.equal(metadata.format, 'jpeg');
    assert.deepEqual(result.original, buffer);
    const { data, info } = await sharp(result.image).raw().toBuffer({ resolveWithObject: true });
    const pixel = (x, y) => [...data.subarray((y * info.width + x) * info.channels, (y * info.width + x) * info.channels + 3)];
    assert.ok(pixel(0, 0).every(channel => channel > 245));
    assert.ok(pixel(272, 272)[1] < 10);
    // The red content must fill the long axis and preserve the 2:1 ratio.
    const inside = width > height ? pixel(10, 140) : pixel(140, 10);
    const outside = width > height ? pixel(272, 120) : pixel(120, 272);
    assert.ok(inside[0] > 245 && inside[1] < 10);
    assert.ok(outside.every(channel => channel > 245));
    if (mode === 'label') assert.equal(result.rawOcrText, 'Takaran saji 100 g');
  }
});
