import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/locacao_veiculo.dart';
import 'api_config.dart';

/// Erro de comunicação com a API (status HTTP inesperado).
class ApiException implements Exception {
  final String mensagem;

  ApiException(this.mensagem);

  @override
  String toString() => 'ApiException: $mensagem';
}

/// Camada de serviço: concentra todas as chamadas HTTP para a API de
/// locações. As telas nunca fazem requisição direto; elas passam pelo
/// repository, que usa este serviço.
///
/// Rotas usadas:
///   GET  /locacoes  -> lista as locações gravadas no PostgreSQL
///   POST /locacoes  -> cadastra uma nova locação
class LocacaoService {
  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  LocacaoService({
    this.baseUrl = apiBaseUrl,
    this.timeout = apiTimeout,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri get _uriLocacoes => Uri.parse('$baseUrl/locacoes');

  /// Busca as locações armazenadas remotamente.
  ///
  /// Lança exceção se a API estiver fora do ar, demorar demais ou responder
  /// com erro; o repository trata isso como "API indisponível".
  Future<List<LocacaoVeiculo>> buscarLocacoes() async {
    final http.Response resposta = await _client
        .get(_uriLocacoes)
        .timeout(timeout);

    if (resposta.statusCode != 200) {
      throw ApiException(
        'Falha ao buscar locações (HTTP ${resposta.statusCode}).',
      );
    }

    final List<dynamic> lista =
        jsonDecode(utf8.decode(resposta.bodyBytes)) as List<dynamic>;
    return lista
        .map((item) => LocacaoVeiculo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Envia uma nova locação para a API e retorna o registro gravado.
  Future<LocacaoVeiculo> enviarLocacao(LocacaoVeiculo locacao) async {
    final http.Response resposta = await _client
        .post(
          _uriLocacoes,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode(locacao.toJson()),
        )
        .timeout(timeout);

    if (resposta.statusCode != 201 && resposta.statusCode != 200) {
      throw ApiException(
        'Falha ao enviar locação (HTTP ${resposta.statusCode}).',
      );
    }

    return LocacaoVeiculo.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
