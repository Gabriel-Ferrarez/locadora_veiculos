import 'package:sqflite/sqflite.dart';

import '../models/locacao_veiculo.dart';
import 'app_database.dart';

/// Acesso à tabela `locacoes` do SQLite local.
///
/// Só sabe falar com o banco do aparelho: não conhece a API. Quem decide
/// quando usar o SQLite ou a API é a camada `repository`.
class LocacaoDao {
  final Future<Database> Function() _abrirBanco;

  /// [abrirBanco] permite trocar o banco nos testes (SQLite em memória).
  LocacaoDao({Future<Database> Function()? abrirBanco})
    : _abrirBanco = abrirBanco ?? getDatabase;

  /// Insere a locação e retorna o id gerado pelo SQLite.
  Future<int> salvar(LocacaoVeiculo locacao) async {
    final Database db = await _abrirBanco();
    final Map<String, dynamic> linha = locacao.toMap()..remove('id');
    return db.insert(tabelaLocacoes, linha);
  }

  /// Todas as locações do aparelho: pendentes primeiro, depois as
  /// sincronizadas, sempre das mais recentes para as mais antigas.
  Future<List<LocacaoVeiculo>> buscarTodas() async {
    final Database db = await _abrirBanco();
    final List<Map<String, dynamic>> resultado = await db.query(
      tabelaLocacoes,
      orderBy: 'sincronizado ASC, id DESC',
    );
    return resultado.map(LocacaoVeiculo.fromMap).toList();
  }

  /// Locações salvas localmente que ainda não chegaram à API.
  Future<List<LocacaoVeiculo>> buscarPendentes() async {
    final Database db = await _abrirBanco();
    final List<Map<String, dynamic>> resultado = await db.query(
      tabelaLocacoes,
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );
    return resultado.map(LocacaoVeiculo.fromMap).toList();
  }

  Future<int> contarPendentes() async {
    final Database db = await _abrirBanco();
    final List<Map<String, Object?>> resultado = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $tabelaLocacoes WHERE sincronizado = 0',
    );
    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  /// Marca uma locação pendente como sincronizada (0 -> 1).
  Future<void> marcarComoSincronizado(int id) async {
    final Database db = await _abrirBanco();
    await db.update(
      tabelaLocacoes,
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Atualiza a cópia local com o que veio da API.
  ///
  /// As linhas já sincronizadas são trocadas pela lista remota; as pendentes
  /// não são tocadas, para nenhum cadastro offline se perder.
  Future<void> substituirSincronizadas(List<LocacaoVeiculo> remotas) async {
    final Database db = await _abrirBanco();
    await db.transaction((txn) async {
      await txn.delete(
        tabelaLocacoes,
        where: 'sincronizado = ?',
        whereArgs: [1],
      );
      final Batch batch = txn.batch();
      for (final LocacaoVeiculo remota in remotas) {
        final Map<String, dynamic> linha =
            remota.copyWith(sincronizado: true).toMap()..remove('id');
        batch.insert(tabelaLocacoes, linha);
      }
      await batch.commit(noResult: true);
    });
  }
}
