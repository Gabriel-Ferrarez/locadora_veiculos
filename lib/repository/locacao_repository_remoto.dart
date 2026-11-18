import '../models/locacao_veiculo.dart';
import '../services/locacao_service.dart';
import 'locacao_repository.dart';

/// Estratégia de persistência remota: tudo vai direto para a API.
///
/// Não guarda nada no aparelho. Se a API estiver fora do ar, o cadastro
/// falha (a exceção sobe para a tela) — é exatamente o problema que a
/// estratégia offline-first resolve.
class LocacaoRepositoryRemoto implements LocacaoRepository {
  final LocacaoService _service;

  LocacaoRepositoryRemoto({LocacaoService? service})
    : _service = service ?? LocacaoService();

  @override
  Future<StatusCadastro> cadastrar(LocacaoVeiculo locacao) async {
    await _service.enviarLocacao(locacao);
    return StatusCadastro.enviadoParaApi;
  }

  @override
  Future<ResultadoListagem> listar() async {
    return ResultadoListagem(await _service.buscarLocacoes());
  }

  /// Nada fica pendente nesta estratégia.
  @override
  Future<ResultadoSincronizacao> sincronizarPendentes() async {
    return const ResultadoSincronizacao(enviados: 0, restantes: 0);
  }

  @override
  Future<int> contarPendentes() async => 0;
}
