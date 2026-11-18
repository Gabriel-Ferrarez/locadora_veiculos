import 'package:flutter_test/flutter_test.dart';
import 'package:locadora_veiculos/database/locacao_dao.dart';
import 'package:locadora_veiculos/models/locacao_veiculo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/banco_em_memoria.dart';

void main() {
  late Database db;
  late LocacaoDao dao;

  setUp(() async {
    db = await abrirBancoEmMemoria();
    dao = LocacaoDao(abrirBanco: () async => db);
  });

  tearDown(() => db.close());

  test('salva e lê as locações do SQLite', () async {
    final int id = await dao.salvar(LocacaoVeiculo(350.0, 1001));

    final List<LocacaoVeiculo> todas = await dao.buscarTodas();
    expect(todas, hasLength(1));
    expect(todas.single.id, id);
    expect(todas.single.numeroContrato, 1001);
    expect(todas.single.valorLocacao, 350.0);
  });

  test('separa pendentes (0) de sincronizadas (1)', () async {
    await dao.salvar(LocacaoVeiculo(100.0, 1, sincronizado: true));
    await dao.salvar(LocacaoVeiculo(200.0, 2));
    await dao.salvar(LocacaoVeiculo(300.0, 3));

    final List<LocacaoVeiculo> pendentes = await dao.buscarPendentes();
    expect(pendentes.map((l) => l.numeroContrato), [2, 3]);
    expect(await dao.contarPendentes(), 2);
  });

  test('lista pendentes primeiro, das mais recentes para as antigas', () async {
    await dao.salvar(LocacaoVeiculo(100.0, 1, sincronizado: true));
    await dao.salvar(LocacaoVeiculo(200.0, 2));
    await dao.salvar(LocacaoVeiculo(300.0, 3, sincronizado: true));
    await dao.salvar(LocacaoVeiculo(400.0, 4));

    final List<LocacaoVeiculo> todas = await dao.buscarTodas();
    expect(todas.map((l) => l.numeroContrato), [4, 2, 3, 1]);
  });

  test('marca uma pendente como sincronizada', () async {
    final int id = await dao.salvar(LocacaoVeiculo(200.0, 2));

    await dao.marcarComoSincronizado(id);

    expect(await dao.contarPendentes(), 0);
    expect((await dao.buscarTodas()).single.sincronizado, isTrue);
  });

  test(
    'substituirSincronizadas troca a cópia remota e preserva pendentes',
    () async {
      await dao.salvar(LocacaoVeiculo(100.0, 1, sincronizado: true));
      await dao.salvar(LocacaoVeiculo(999.0, 50)); // pendente

      await dao.substituirSincronizadas([
        LocacaoVeiculo(100.0, 1),
        LocacaoVeiculo(250.0, 7),
      ]);

      final List<LocacaoVeiculo> todas = await dao.buscarTodas();
      expect(todas, hasLength(3));
      expect(todas.first.numeroContrato, 50);
      expect(todas.first.sincronizado, isFalse);
      expect(todas.where((l) => l.sincronizado).map((l) => l.numeroContrato), [
        7,
        1,
      ]);
    },
  );
}
