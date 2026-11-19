const { Pool } = require('pg');

/**
 * Cria o pool de conexões com o PostgreSQL a partir de DATABASE_URL.
 *
 * No Render, a variável é preenchida automaticamente pelo render.yaml com a
 * URL interna do banco. Localmente, defina no arquivo .env (veja .env.example).
 */
function criarPool(connectionString = process.env.DATABASE_URL) {
  if (!connectionString) {
    throw new Error(
      'Defina a variável DATABASE_URL com a conexão do PostgreSQL.',
    );
  }

  // A URL externa do Render (*.render.com) exige SSL (com verificação do
  // certificado); a URL interna, usada pela API no Render, e um PostgreSQL
  // local não usam SSL.
  const precisaSsl =
    /render\.com/.test(connectionString) ||
    process.env.PGSSLMODE === 'require';

  return new Pool({ connectionString, ssl: precisaSsl });
}

/** Cria a tabela da entidade principal, se ainda não existir. */
async function criarTabela(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS locacoes (
      id SERIAL PRIMARY KEY,
      numero_contrato INTEGER NOT NULL,
      valor_locacao NUMERIC(12, 2) NOT NULL,
      criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
}

module.exports = { criarPool, criarTabela };
