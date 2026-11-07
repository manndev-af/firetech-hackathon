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
