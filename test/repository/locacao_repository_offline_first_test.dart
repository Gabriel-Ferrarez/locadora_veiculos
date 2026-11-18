import 'package:flutter_test/flutter_test.dart';
import 'package:locadora_veiculos/database/locacao_dao.dart';
import 'package:locadora_veiculos/models/locacao_veiculo.dart';
import 'package:locadora_veiculos/repository/locacao_repository.dart';
import 'package:locadora_veiculos/repository/locacao_repository_offline_first.dart';
import 'package:locadora_veiculos/services/locacao_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/api_falsa.dart';
import '../helpers/banco_em_memoria.dart';

/// Os três cenários obrigatórios do enunciado (seção 11), usando o SQLite
/// real em memória e o LocacaoService real contra uma API simulada.
void main() {
  late Database db;
  late LocacaoDao dao;
  late ApiFalsa api;
  late LocacaoRepositoryOfflineFirst repository;

  setUp(() async {
    db = await abrirBancoEmMemoria();
    dao = LocacaoDao(abrirBanco: () async => db);
    api = ApiFalsa();
    repository = LocacaoRepositoryOfflineFirst(
      dao: dao,
      service: LocacaoService(baseUrl: 'https://api.teste', client: api.client),
    );
  });

  tearDown(() => db.close());

  group('Teste 1 — API funcionando', () {
    test('o cadastro chega à API e fica no SQLite como sincronizado', () async {
      final StatusCadastro status = await repository.cadastrar(
        LocacaoVeiculo(350.0, 1001),
      );

      expect(status, StatusCadastro.enviadoParaApi);
      expect(api.registros, hasLength(1));
      expect(api.registros.single['numeroContrato'], 1001);

      final List<LocacaoVeiculo> locais = await dao.buscarTodas();
      expect(locais.single.sincronizado, isTrue);
      expect(await repository.contarPendentes(), 0);
    });

    test('a listagem traz os registros que estão na API', () async {
      api.registros.add({'id': 1, 'numeroContrato': 7, 'valorLocacao': 90});

      final ResultadoListagem resultado = await repository.listar();

      expect(resultado.apiIndisponivel, isFalse);
      expect(resultado.locacoes.single.numeroContrato, 7);
      expect(resultado.locacoes.single.sincronizado, isTrue);
    });
  });

  group('Teste 2 — API indisponível', () {
    test('o cadastro não se perde: vai para o SQLite como pendente', () async {
      api.online = false;

      final StatusCadastro status = await repository.cadastrar(
        LocacaoVeiculo(1280.5, 1002),
      );

      expect(status, StatusCadastro.salvoComoPendente);
      expect(api.registros, isEmpty);

      final List<LocacaoVeiculo> pendentes = await dao.buscarPendentes();
      expect(pendentes.single.numeroContrato, 1002);
      expect(pendentes.single.valorLocacao, 1280.5);
      expect(await repository.contarPendentes(), 1);
    });

    test('resposta de erro da API também gera pendente', () async {
      api.statusErro = 500;

      final StatusCadastro status = await repository.cadastrar(
        LocacaoVeiculo(10.0, 1),
      );

      expect(status, StatusCadastro.salvoComoPendente);
      expect(await repository.contarPendentes(), 1);
    });

    test('a listagem mostra o que está salvo no aparelho', () async {
      await repository.cadastrar(LocacaoVeiculo(350.0, 1001)); // online
      api.online = false;
      await repository.cadastrar(LocacaoVeiculo(1280.5, 1002)); // offline

      final ResultadoListagem resultado = await repository.listar();

      expect(resultado.apiIndisponivel, isTrue);
      expect(resultado.locacoes.map((l) => l.numeroContrato), [1002, 1001]);
      expect(resultado.totalPendentes, 1);
    });

    test('os registros continuam lá ao "reabrir o app"', () async {
      api.online = false;
      await repository.cadastrar(LocacaoVeiculo(1280.5, 1002));

      // Novo repository (como num novo start do app) no mesmo banco.
      final LocacaoRepositoryOfflineFirst reaberto =
          LocacaoRepositoryOfflineFirst(
            dao: LocacaoDao(abrirBanco: () async => db),
            service: LocacaoService(
              baseUrl: 'https://api.teste',
              client: api.client,
            ),
          );

      expect(await reaberto.contarPendentes(), 1);
    });
  });

  group('Teste 3 — API volta e sincroniza', () {
    test('envia os pendentes e marca como sincronizados', () async {
      api.online = false;
      await repository.cadastrar(LocacaoVeiculo(1280.5, 1002));
      await repository.cadastrar(LocacaoVeiculo(80.0, 1003));
      api.online = true;

      final ResultadoSincronizacao resultado = await repository
          .sincronizarPendentes();

      expect(resultado.enviados, 2);
      expect(resultado.restantes, 0);
      expect(resultado.apiIndisponivel, isFalse);
      expect(api.registros.map((r) => r['numeroContrato']), [1002, 1003]);
      expect(await repository.contarPendentes(), 0);
    });

    test('depois de sincronizar, a lista não duplica registros', () async {
      api.online = false;
      await repository.cadastrar(LocacaoVeiculo(1280.5, 1002));
      api.online = true;
      await repository.sincronizarPendentes();

      final ResultadoListagem resultado = await repository.listar();

      expect(resultado.locacoes, hasLength(1));
      expect(resultado.locacoes.single.sincronizado, isTrue);
    });

    test('se a API continuar fora, nada se perde', () async {
      api.online = false;
      await repository.cadastrar(LocacaoVeiculo(1280.5, 1002));

      final ResultadoSincronizacao resultado = await repository
          .sincronizarPendentes();

      expect(resultado.apiIndisponivel, isTrue);
      expect(resultado.enviados, 0);
      expect(resultado.restantes, 1);
      expect(await repository.contarPendentes(), 1);
    });

    test('sem pendentes, não envia nada', () async {
      final ResultadoSincronizacao resultado = await repository
          .sincronizarPendentes();

      expect(resultado.enviados, 0);
      expect(api.registros, isEmpty);
    });
  });
}
