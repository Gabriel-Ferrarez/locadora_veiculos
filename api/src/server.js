const { criarApp } = require('./app');
const { criarPool, criarTabela } = require('./db');

const PORTA = process.env.PORT || 3000;

async function iniciar() {
  const pool = criarPool();
  await criarTabela(pool);

  criarApp(pool).listen(PORTA, () => {
    console.log(`API da Locadora de Veículos rodando na porta ${PORTA}`);
  });
}

iniciar().catch((erro) => {
  console.error('Falha ao iniciar a API:', erro);
  process.exit(1);
});
