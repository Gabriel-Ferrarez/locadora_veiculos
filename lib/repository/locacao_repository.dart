import '../models/locacao_veiculo.dart';

/// O que aconteceu com um cadastro.
enum StatusCadastro {
  /// Chegou à API (PostgreSQL) e foi guardado no SQLite como sincronizado.
  enviadoParaApi,

  /// A API falhou: o registro foi salvo no SQLite como pendente (0).
  salvoComoPendente,

  /// Estratégia somente local: salvo no SQLite, sem tentar a API.
  salvoLocalmente,
}

class ResultadoListagem {
  final List<LocacaoVeiculo> locacoes;

  /// `true` quando a API foi consultada e não respondeu; nesse caso a lista
  /// mostra o que está salvo no aparelho.
  final bool apiIndisponivel;

  const ResultadoListagem(this.locacoes, {this.apiIndisponivel = false});

  int get totalPendentes => locacoes.where((l) => !l.sincronizado).length;
}

class ResultadoSincronizacao {
  /// Quantos registros pendentes foram enviados à API nesta sincronização.
  final int enviados;

  /// Quantos continuam pendentes (a API caiu no meio do caminho).
  final int restantes;

  final bool apiIndisponivel;

  const ResultadoSincronizacao({
    required this.enviados,
    required this.restantes,
    this.apiIndisponivel = false,
  });
}

/// Camada repository: único ponto de acesso aos dados de locações.
///
/// As telas conversam só com esta interface. Quem decide se usa o SQLite,
/// a API ou os dois é a implementação escolhida no `main.dart`:
/// - [LocacaoRepositoryLocal]: persistência local (somente SQLite);
/// - [LocacaoRepositoryRemoto]: persistência remota (somente API);
/// - [LocacaoRepositoryOfflineFirst]: API com fallback no SQLite e
///   sincronização manual dos pendentes (a usada pelo app).
abstract class LocacaoRepository {
  Future<StatusCadastro> cadastrar(LocacaoVeiculo locacao);

  Future<ResultadoListagem> listar();

  Future<ResultadoSincronizacao> sincronizarPendentes();

  Future<int> contarPendentes();
}
