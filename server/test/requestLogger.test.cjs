const { test } = require('node:test');
const assert = require('node:assert/strict');
const { mkdtemp, readdir, readFile, rm } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const { once } = require('node:events');
const express = require('express');
const multer = require('multer');
require('ts-node/register');
const { createRequestLogger } = require('../src/middleware/requestLogger');

test('Morgan writes request/response JSON and redacts secrets, private fields and image bytes', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'nutrilens-logs-'));
  const app = express();
  app.use(createRequestLogger(directory));
  app.use(express.json());
  app.post('/debug', (req, res) => res.status(201).json({ nutrients: { protein_g: 5 }, password: 'response-secret', context: { name: 'private-person' }, ttsSummary: 'Cek lagi porsinya, ya.' }));
  app.post('/upload', multer().single('image'), (req, res) => res.json({ mode: req.body.mode }));
  const { compareUpload } = require('../src/middleware/compareUpload');
  const { domainErrorHandler } = require('../src/utils/domainError');
  app.post('/api/v1/comparisons', compareUpload, (_req, res) => res.json({ summary: 'private-compare-result' }));
  app.post('/api/v1/assistant/messages', (_req, res) => res.json({ reply: 'private-assistant-reply' }));
  app.use(domainErrorHandler);
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  try {
    const base = `http://127.0.0.1:${server.address().port}`;
    const response = await fetch(`${base}/debug?api_key=query-secret`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer auth-secret', 'Idempotency-Key': 'debug-id' },
      body: JSON.stringify({ mode: 'food', password: 'request-secret', rawOcrText: 'private-ocr', image: { base64: 'image-secret' } }),
    });
    assert.equal(response.status, 201);
    assert.equal((await response.json()).password, 'response-secret');
    const form = new FormData();
    form.set('mode', 'label');
    form.set('rawOcrText', 'multipart-private-ocr');
    form.set('image', new Blob(['binary-secret'], { type: 'image/jpeg' }), 'photo.jpg');
    assert.equal((await fetch(`${base}/upload`, { method: 'POST', body: form })).status, 200);
    for (const metadata of ['private-compare-metadata', 'x'.repeat(256 * 1024 + 1)]) {
      const comparison = new FormData();
      comparison.set('metadata', metadata);
      await fetch(`${base}/api/v1/comparisons`, { method: 'POST', body: comparison });
    }
    // Express routing ignores case; privacy must also apply before JSON parsing fails.
    await fetch(`${base}/API/V1/COMPARISONS/`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{"metadata":"private-parser-input"' });
    await fetch(`${base}/api/v1/assistant/messages?text=private-assistant-query`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ message: 'private-assistant-input' }) });
    await fetch(`${base}/API/V1/ASSISTANT/MESSAGES/`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{"message":"private-assistant-parser"' });
    let lines = [];
    for (let attempt = 0; attempt < 100 && lines.length < 7; attempt++) {
      const files = await readdir(directory);
      const text = (await Promise.all(files.map(file => readFile(join(directory, file), 'utf8')))).join('');
      lines = text.trim().split('\n').filter(Boolean);
      if (lines.length < 7) await new Promise(resolve => setTimeout(resolve, 20));
    }
    assert.equal(lines.length, 7);
    const logs = lines.map(line => JSON.parse(line));
    const log = logs.find(item => item.path === '/debug');
    assert.equal(log.request.body.mode, 'food');
    assert.equal(log.request.headers['idempotency-key'], 'debug-id');
    assert.equal(log.status, 201);
    assert.equal(log.response.body.nutrients.protein_g, 5);
    assert.equal(log.response.body.ttsSummary, 'Cek lagi porsinya, ya.');
    assert.equal(typeof log.durationMs, 'number');
    assert.deepEqual(logs.find(item => item.path === '/upload').request.file, { mimeType: 'image/jpeg', bytes: 13 });
    for (const item of logs.filter(item => ['/api/v1/comparisons', '/api/v1/assistant/messages'].includes(item.path.toLowerCase().replace(/\/+$/, '')))) {
      assert.equal(item.request.body, '[omitted]');
      assert.equal(item.response.body, '[omitted]');
      assert.equal(item.query, '[omitted]');
    }
    for (const secret of ['query-secret', 'auth-secret', 'request-secret', 'response-secret', 'private-person', 'private-ocr', 'image-secret', 'binary-secret', 'private-compare-result', 'private-compare-metadata', 'private-parser-input']) assert.ok(!lines.join('').includes(secret), secret);
    assert.ok(!lines.join('').includes('private-assistant'));
  } finally {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
    await rm(directory, { recursive: true, force: true });
  }
});
