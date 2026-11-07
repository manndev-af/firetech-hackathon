const assert = require('node:assert/strict');
const { once } = require('node:events');
const { test } = require('node:test');

process.env.NODE_ENV = 'test';
process.env.API_PREFIX = '/api/v1';
process.env.ENABLE_DEMO_USER = 'false';
require('ts-node/register');
const { createApp } = require('../src/app');

test('Swagger serves local assets and documents working routes with a custom prefix', async () => {
  const server = createApp().listen(0, '127.0.0.1');
  await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}`;
  const request = (path, options) => fetch(`${base}${path}`, options);
  try {
    const json = await request('/api/v1/openapi.json');
    assert.equal(json.status, 200);
    const spec = await json.json();
    assert.equal(spec.openapi, '3.0.3');
    assert.deepEqual(Object.keys(spec.paths).sort(), ['/health', '/api/v1/health', '/api/v1/health/readiness', '/api/v1/health/liveness', '/api/v1/users', '/api/v1/users/{id}'].sort());
    const ids = Object.values(spec.paths).flatMap(path =>
      Object.values(path).filter(operation => operation.operationId).map(operation => operation.operationId));
    assert.equal(ids.length, 9);
    assert.equal(new Set(ids).size, ids.length);
    for (const path of ['/health', '/api/v1/health', '/api/v1/health/readiness', '/api/v1/health/liveness', '/api/v1/users', '/api/v1/users/1']) {
      assert.equal((await request(path)).status, 200, path);
    }
    const ui = await request('/api/v1/docs/');
    assert.equal(ui.status, 200);
    assert.match(await ui.text(), /swagger-ui/);
    assert.ok(!ui.headers.get('content-security-policy').includes('upgrade-insecure-requests'));
    for (const asset of ['swagger-ui.css', 'swagger-ui-bundle.js', 'swagger-ui-init.js']) {
      assert.equal((await request(`/api/v1/docs/${asset}`)).status, 200);
    }
    const schema = spec.paths['/api/v1/users'].post.requestBody.content['application/json'].schema;
    assert.deepEqual(schema.required, ['name', 'email']);
    assert.equal(schema.properties.age.maximum, 150);
    const options = body => ({ method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    assert.equal((await request('/api/v1/users', options({ name: '', email: 'bad', age: 151 }))).status, 400);
    const created = await request('/api/v1/users', options({ name: 'Test', email: 'test@example.com' }));
    assert.equal(created.status, 201);
    const { data } = await created.json();
    const updated = await request(`/api/v1/users/${data.id}`, { ...options({ age: 20 }), method: 'PUT' });
    assert.equal(updated.status, 200);
    assert.equal((await updated.json()).data.age, 20);
    const deleted = await request(`/api/v1/users/${data.id}`, { method: 'DELETE' });
    assert.equal(deleted.status, 204);
    assert.equal(await deleted.text(), '');
    assert.equal((await request(`/api/v1/users/${data.id}`)).status, 404);
  } finally {
    server.closeAllConnections();
    await new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  }
});
