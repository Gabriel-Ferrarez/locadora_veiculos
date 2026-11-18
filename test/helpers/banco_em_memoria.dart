import 'package:locadora_veiculos/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Banco SQLite real, mas em memória, com o mesmo esquema do app.
/// Cada chamada devolve um banco novo e vazio.
Future<Database> abrirBancoEmMemoria() async {
  sqfliteFfiInit();
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) => criarTabelas(db),
      singleInstance: false,
    ),
  );
}
