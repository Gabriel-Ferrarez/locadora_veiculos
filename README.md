# Locadora de Veículos

**Nome da temática do aplicativo:** 20. Locadora de Veículos

**Nome completo do estudante:** Gabriel Antônio Ferrarez Oliveira

**Link da API publicada:** https://locadora-veiculos-api.onrender.com

**Descrição resumida da aplicação:** aplicativo Flutter de uma locadora de veículos para registrar locações (nº do contrato e valor da locação). Os cadastros são enviados para uma API própria (Node.js + Express) com banco PostgreSQL no Render e também ficam guardados no SQLite do aparelho. Se a API estiver fora do ar, o cadastro não se perde: é salvo localmente como **pendente** e pode ser enviado depois pelo botão **Sincronizar pendentes** (estratégia offline-first).

Projeto avaliativo do 2º bimestre de Programação para Dispositivos Móveis II, continuação do app do 1º bimestre (feito a partir do Projeto Bank).

---

## Arquitetura

```
Telas (screens)
   ↓
Camada Repository  ── decide entre API e SQLite
   ↓                         ↓
LocacaoService (HTTP)    LocacaoDao (SQLite local)
   ↓
API Node.js + Express (Render)
   ↓
PostgreSQL (Render)
```

As telas só conversam com o `LocacaoRepository`. Elas não sabem se os dados vieram da API ou do SQLite.

## Estrutura do projeto

```
lib/
├── components/   editor de campo, item da lista e selo Sincronizada/Pendente
├── database/     SQLite: abertura do banco e LocacaoDao (tabela locacoes)
├── models/       LocacaoVeiculo (com toMap/fromMap e toJson/fromJson)
├── repository/   interface + estratégias local, remota e offline-first
├── screens/      dashboard, lista e formulário de locações
├── services/     LocacaoService (chamadas HTTP) e URL da API
└── main.dart     escolhe a estratégia de persistência usada pelo app
api/              API Node.js + Express + PostgreSQL
test/             testes do app (modelo, SQLite, repository e telas)
render.yaml       blueprint do Render (API + PostgreSQL)
```

## Persistência local (SQLite)

Tabela `locacoes` no arquivo `locadora.db`:

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INTEGER (PK, autoincremento) | id local |
| `valor_locacao` | REAL | valor da locação |
| `numero_contrato` | INTEGER | nº do contrato |
| `sincronizado` | INTEGER | **1** = sincronizado, **0** = pendente |

Os registros continuam no aparelho depois de fechar e abrir o app.

## Offline-first

A estratégia usada pelo app é `LocacaoRepositoryOfflineFirst` (definida no `main.dart`). O projeto também tem `LocacaoRepositoryLocal` (só SQLite) e `LocacaoRepositoryRemoto` (só API), e dá para trocar de estratégia sem mexer nas telas.

**API disponível:** o cadastro vai para a API e é guardado no SQLite como sincronizado (1).

**API indisponível:** a tentativa de envio falha, o cadastro é salvo no SQLite como pendente (0) e a lista mostra o aviso "API indisponível" com o selo **Pendente** no registro.

**API disponível de novo:** o botão **Sincronizar pendentes** (na lista e no ícone da barra superior) busca os pendentes no SQLite, envia cada um para a API e marca como sincronizados (1).

## API

Node.js + Express + PostgreSQL, na pasta [`api/`](api/).

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/` | Status da API e lista de rotas |
| `GET` | `/locacoes` | Lista todas as locações gravadas no PostgreSQL |
| `GET` | `/locacoes/:id` | Busca uma locação pelo id |
| `POST` | `/locacoes` | Cadastra uma locação |

Corpo do `POST /locacoes`:

```json
{ "numeroContrato": 1001, "valorLocacao": 350.0 }
```

Resposta (`201 Created`):

```json
{ "id": 1, "numeroContrato": 1001, "valorLocacao": 350, "criadoEm": "2026-11-18T23:38:35.466Z" }
```

Dados inválidos retornam `400` com a lista de erros.

Tabela no PostgreSQL: `locacoes (id SERIAL, numero_contrato INTEGER, valor_locacao NUMERIC(12,2), criado_em TIMESTAMPTZ)`, criada automaticamente quando a API sobe.

### Deploy no Render

1. No Render: **New > Blueprint** e selecione este repositório.
2. O `render.yaml` cria o banco `locadora-veiculos-db` (PostgreSQL) e o serviço `locadora-veiculos-api`, já com a variável `DATABASE_URL` ligada ao banco.
3. Depois do deploy, confira a URL do serviço e, se for diferente, atualize `lib/services/api_config.dart` e o link no topo deste README.

### Rodar a API localmente

```bash
cd api
npm install
cp .env.example .env   # ajuste a DATABASE_URL para um PostgreSQL local
npm run dev
```

## Executar o app

```bash
flutter pub get
flutter run
```

## Testes

```bash
flutter test          # app: modelo, SQLite, offline-first e telas
cd api && npm test    # API: rotas com PostgreSQL em memória
```

## Roteiro de validação (seção 11 do enunciado)

1. **API funcionando:** cadastre uma locação, veja o selo **Sincronizada** e confira em `/locacoes` na URL da API.
2. **API indisponível:** troque `apiBaseUrl` em `lib/services/api_config.dart` por um endereço inválido (ou ative o modo avião), cadastre uma locação e veja o aviso e o selo **Pendente**.
3. **Sincronizar:** restaure a URL correta (ou desative o modo avião), toque em **Sincronizar pendentes** e confira em `/locacoes` que o registro chegou.

> No plano gratuito, a API "dorme" sem uso e leva alguns segundos para acordar. Abra a URL da API no navegador antes de começar.

## 1º bimestre

- **Entidade:** `LocacaoVeiculo`, com `valorLocacao` (`double`) e `numeroContrato` (`int`)
- **Ícone:** `Icons.directions_car`
- `evidencias/formulario.png`: formulário de cadastro com os campos preenchidos
- `evidencias/lista.png`: lista depois da confirmação, com o registro novo
