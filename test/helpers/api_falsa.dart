import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Simula a API do Render: guarda as locações em memória e pode ser
/// "derrubada" ([online] = false) para testar o offline-first.
class ApiFalsa {
  bool online = true;

  /// Quando definido, a API responde com este status em vez de funcionar.
  int? statusErro;

  final List<Map<String, dynamic>> registros = [];
  int _proximoId = 1;

  late final http.Client client = MockClient((request) async {
    if (!online) {
      throw http.ClientException('Falha de conexão (API fora do ar)');
    }
    if (statusErro != null) {
      return http.Response('{"erro":"falha"}', statusErro!);
    }
    if (request.url.path != '/locacoes') {
      return http.Response('{"erro":"rota não encontrada"}', 404);
    }

    if (request.method == 'GET') {
      return http.Response(
        jsonEncode(registros),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    if (request.method == 'POST') {
      final Map<String, dynamic> corpo =
          jsonDecode(request.body) as Map<String, dynamic>;
      final Map<String, dynamic> registro = {'id': _proximoId++, ...corpo};
      registros.add(registro);
      return http.Response(
        jsonEncode(registro),
        201,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    return http.Response('{"erro":"método não suportado"}', 405);
  });
}
