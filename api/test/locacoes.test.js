const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { newDb } = require('pg-mem');

const { criarApp } = require('../src/app');
const { criarTabela } = require('../src/db');

let app;

// Cada teste roda num PostgreSQL em memória novo e vazio.
beforeEach(async () => {
  const { Pool } = newDb().adapters.createPg();
  const pool = new Pool();
  await criarTabela(pool);
  app = criarApp(pool);
});

test('GET / informa que a API está no ar', async () => {
  const res = await request(app).get('/');
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'online');
});

test('GET /locacoes começa vazio', async () => {
  const res = await request(app).get('/locacoes');
  assert.equal(res.status, 200);
  assert.deepEqual(res.body, []);
});

test('POST /locacoes cadastra e GET /locacoes lista', async () => {
  const criada = await request(app)
    .post('/locacoes')
    .send({ numeroContrato: 1001, valorLocacao: 350.5 });

  assert.equal(criada.status, 201);
  assert.equal(criada.body.numeroContrato, 1001);
  assert.equal(criada.body.valorLocacao, 350.5);
  assert.ok(Number.isInteger(criada.body.id));

  const lista = await request(app).get('/locacoes');
  assert.equal(lista.status, 200);
  assert.equal(lista.body.length, 1);
  assert.equal(lista.body[0].numeroContrato, 1001);
  assert.equal(typeof lista.body[0].valorLocacao, 'number');
});

test('POST /locacoes aceita o formato enviado pelo app Flutter', async () => {
  // jsonEncode do Dart manda double como "350.0" e int como "1001".
  const res = await request(app)
    .post('/locacoes')
    .set('Content-Type', 'application/json; charset=utf-8')
    .send('{"numeroContrato":1001,"valorLocacao":350.0}');

  assert.equal(res.status, 201);
  assert.equal(res.body.valorLocacao, 350);
});

test('POST /locacoes rejeita dados inválidos', async () => {
  const res = await request(app)
    .post('/locacoes')
    .send({ numeroContrato: 'abc', valorLocacao: -5 });

  assert.equal(res.status, 400);
  assert.equal(res.body.erros.length, 2);
});

test('POST /locacoes rejeita JSON malformado', async () => {
  const res = await request(app)
    .post('/locacoes')
    .set('Content-Type', 'application/json')
    .send('{"numeroContrato":');

  assert.equal(res.status, 400);
});

test('GET /locacoes/:id busca uma locação', async () => {
  const criada = await request(app)
    .post('/locacoes')
    .send({ numeroContrato: 7, valorLocacao: 90 });

  const res = await request(app).get(`/locacoes/${criada.body.id}`);
  assert.equal(res.status, 200);
  assert.equal(res.body.numeroContrato, 7);

  const inexistente = await request(app).get('/locacoes/999');
  assert.equal(inexistente.status, 404);
});

test('rota desconhecida responde 404', async () => {
  const res = await request(app).get('/nao-existe');
  assert.equal(res.status, 404);
});
