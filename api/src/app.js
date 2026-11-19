const express = require('express');
const cors = require('cors');

const COLUNAS = 'id, numero_contrato, valor_locacao, criado_em';

/** Linha do PostgreSQL (snake_case) -> JSON da API (camelCase). */
function paraJson(linha) {
  return {
    id: linha.id,
    numeroContrato: linha.numero_contrato,
    // NUMERIC chega do driver como texto; o app espera número.
    valorLocacao: Number(linha.valor_locacao),
    criadoEm: linha.criado_em,
  };
}

function validarLocacao(corpo) {
  const { numeroContrato, valorLocacao } = corpo ?? {};
  const erros = [];

  if (!Number.isInteger(numeroContrato) || numeroContrato <= 0) {
    erros.push('numeroContrato deve ser um número inteiro positivo.');
  }
  if (
    typeof valorLocacao !== 'number' ||
    !Number.isFinite(valorLocacao) ||
    valorLocacao < 0
  ) {
    erros.push('valorLocacao deve ser um número maior ou igual a zero.');
  }
  return erros;
}

/**
 * Monta a API de locações sobre um pool do PostgreSQL.
 *
 * Rotas:
 *   GET  /               -> informações e status da API
 *   GET  /locacoes       -> lista todas as locações
 *   GET  /locacoes/:id   -> busca uma locação pelo id
 *   POST /locacoes       -> cadastra uma locação
 */
function criarApp(pool) {
  const app = express();
  app.use(cors());
  app.use(express.json());

  app.get('/', (req, res) => {
    res.json({
      api: 'Locadora de Veículos',
      status: 'online',
      rotas: ['GET /locacoes', 'GET /locacoes/:id', 'POST /locacoes'],
    });
  });

  app.get('/locacoes', async (req, res) => {
    const { rows } = await pool.query(
      `SELECT ${COLUNAS} FROM locacoes ORDER BY id`,
    );
    res.json(rows.map(paraJson));
  });

  app.get('/locacoes/:id', async (req, res) => {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ erro: 'id inválido.' });
    }

    const { rows } = await pool.query(
      `SELECT ${COLUNAS} FROM locacoes WHERE id = $1`,
      [id],
    );
    if (rows.length === 0) {
      return res.status(404).json({ erro: 'Locação não encontrada.' });
    }
    res.json(paraJson(rows[0]));
  });

  app.post('/locacoes', async (req, res) => {
    const erros = validarLocacao(req.body);
    if (erros.length > 0) {
      return res.status(400).json({ erros });
    }

    const { numeroContrato, valorLocacao } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO locacoes (numero_contrato, valor_locacao)
       VALUES ($1, $2)
       RETURNING ${COLUNAS}`,
      [numeroContrato, valorLocacao],
    );
    res.status(201).json(paraJson(rows[0]));
  });

  app.use((req, res) => {
    res.status(404).json({ erro: 'Rota não encontrada.' });
  });

  // eslint-disable-next-line no-unused-vars
  app.use((erro, req, res, next) => {
    if (erro.type === 'entity.parse.failed') {
      return res.status(400).json({ erro: 'JSON inválido no corpo da requisição.' });
    }
    console.error(erro);
    res.status(500).json({ erro: 'Erro interno no servidor.' });
  });

  return app;
}

module.exports = { criarApp };
