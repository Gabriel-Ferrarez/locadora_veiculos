// pacote "path": monta o caminho do arquivo do banco de forma cross-platform.
import 'package:path/path.dart';

// pacote sqflite: API para trabalhar com SQLite em Flutter/Dart.
import 'package:sqflite/sqflite.dart';

const String nomeArquivoBanco = 'locadora.db';
const String tabelaLocacoes = 'locacoes';

/// Abre (ou cria, na primeira execução) o banco local do aparelho.
///
/// O arquivo fica salvo no armazenamento do app, então os registros continuam
/// disponíveis depois de fechar e abrir o aplicativo de novo.
Future<Database> getDatabase() async {
  final String path = join(await getDatabasesPath(), nomeArquivoBanco);
  return openDatabase(
    path,
    onCreate: (db, version) => criarTabelas(db),
    version: 1,
  );
}

/// Cria a tabela da entidade principal.
///
/// `sincronizado` controla o offline-first:
///   1 -> registro sincronizado (já está na API / PostgreSQL)
///   0 -> registro pendente de sincronização
Future<void> criarTabelas(Database db) async {
  await db.execute(
    'CREATE TABLE $tabelaLocacoes('
    'id INTEGER PRIMARY KEY AUTOINCREMENT, '
    'valor_locacao REAL NOT NULL, '
    'numero_contrato INTEGER NOT NULL, '
    'sincronizado INTEGER NOT NULL DEFAULT 0)',
  );
}
