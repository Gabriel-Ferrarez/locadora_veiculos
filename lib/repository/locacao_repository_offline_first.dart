import 'dart:developer' as developer;

import '../database/locacao_dao.dart';
import '../models/locacao_veiculo.dart';
import '../services/locacao_service.dart';
import 'locacao_repository.dart';

/// Estratégia offline-first (Aula 5): API como destino principal e SQLite
/// como garantia de que nenhum cadastro se perde.
///
/// Cadastro:
///   tenta a API -> deu certo -> guarda no SQLite como sincronizado (1)
///               -> falhou    -> guarda no SQLite como pendente (0)
///
/// Sincronização manual:
///   busca os pendentes no SQLite -> envia cada um à API
///   -> marca como sincronizado (1) no SQLite
class LocacaoRepositoryOfflineFirst implements LocacaoRepository {
  final LocacaoDao _dao;
  final LocacaoService _service;

  LocacaoRepositoryOfflineFirst({LocacaoDao? dao, LocacaoService? service})
    : _dao = dao ?? LocacaoDao(),
      _service = service ?? LocacaoService();

  @override
  Future<StatusCadastro> cadastrar(LocacaoVeiculo locacao) async {
    try {
      await _service.enviarLocacao(locacao);
    } catch (erro) {
      // API indisponível: o cadastro NÃO é perdido, fica pendente no aparelho.
      _registrarFalha('cadastro', erro);
      await _dao.salvar(locacao.copyWith(sincronizado: false));
      return StatusCadastro.salvoComoPendente;
    }

    await _dao.salvar(locacao.copyWith(sincronizado: true));
    return StatusCadastro.enviadoParaApi;
  }

  /// Com a API no ar, atualiza a cópia local com os registros remotos e
  /// devolve tudo (remotos + pendentes). Sem a API, devolve o que está
  /// salvo no aparelho.
  @override
  Future<ResultadoListagem> listar() async {
    final List<LocacaoVeiculo> remotas;
    try {
      remotas = await _service.buscarLocacoes();
    } catch (erro) {
      _registrarFalha('listagem', erro);
      return ResultadoListagem(await _dao.buscarTodas(), apiIndisponivel: true);
    }

    await _dao.substituirSincronizadas(remotas);
    return ResultadoListagem(await _dao.buscarTodas());
  }

  @override
  Future<ResultadoSincronizacao> sincronizarPendentes() async {
    final List<LocacaoVeiculo> pendentes = await _dao.buscarPendentes();
    int enviados = 0;

    for (final LocacaoVeiculo pendente in pendentes) {
      try {
        await _service.enviarLocacao(pendente);
      } catch (erro) {
        // A API caiu de novo: para aqui e mantém o restante como pendente.
        _registrarFalha('sincronização', erro);
        return ResultadoSincronizacao(
          enviados: enviados,
          restantes: pendentes.length - enviados,
          apiIndisponivel: true,
        );
      }
      await _dao.marcarComoSincronizado(pendente.id!);
      enviados++;
    }

    return ResultadoSincronizacao(enviados: enviados, restantes: 0);
  }

  @override
  Future<int> contarPendentes() => _dao.contarPendentes();

  void _registrarFalha(String operacao, Object erro) {
    developer.log(
      'API indisponível durante a $operacao: $erro',
      name: 'LocacaoRepositoryOfflineFirst',
    );
  }
}
