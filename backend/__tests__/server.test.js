const request = require('supertest');
const app = require('../src/server');

test('GET /health returns ok', async () => {
  const res = await request(app).get('/health');
  expect(res.statusCode).toBe(200);
  expect(res.body.status).toBe('ok');
});

test('POST /api/notes creates note', async () => {
  const res = await request(app).post('/api/notes').send({ title: 'Test', content: 'Hello' });
  expect(res.statusCode).toBe(201);
  expect(res.body.title).toBe('Test');
});

test('GET /metrics returns metrics', async () => {
  const res = await request(app).get('/metrics');
  expect(res.statusCode).toBe(200);
  expect(res.text).toContain('http_request_duration_seconds');
});

test('POST without title returns 400', async () => {
  const res = await request(app).post('/api/notes').send({ content: 'No title' });
  expect(res.statusCode).toBe(400);
});
