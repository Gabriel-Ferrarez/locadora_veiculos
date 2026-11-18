import 'package:flutter_test/flutter_test.dart';
import 'package:locadora_veiculos/models/locacao_veiculo.dart';

void main() {
  group('LocacaoVeiculo', () {
    test('nasce pendente por padrão', () {
      expect(LocacaoVeiculo(350.0, 1001).sincronizado, isFalse);
    });

    test('toMap grava sincronizado como 1/0 e colunas em snake_case', () {
      final Map<String, dynamic> pendente = LocacaoVeiculo(350.0, 1001).toMap();
      expect(pendente, {
        'valor_locacao': 350.0,
        'numero_contrato': 1001,
        'sincronizado': 0,
      });

      final Map<String, dynamic> sincronizada = LocacaoVeiculo(
        350.0,
        1001,
        id: 7,
        sincronizado: true,
      ).toMap();
      expect(sincronizada['id'], 7);
      expect(sincronizada['sincronizado'], 1);
    });

    test('fromMap lê a linha do SQLite', () {
      final LocacaoVeiculo locacao = LocacaoVeiculo.fromMap({
        'id': 3,
        'valor_locacao': 1280.5,
        'numero_contrato': 1002,
        'sincronizado': 0,
      });
      expect(locacao.id, 3);
      expect(locacao.valorLocacao, 1280.5);
      expect(locacao.numeroContrato, 1002);
      expect(locacao.sincronizado, isFalse);
    });

    test('toJson envia só os campos da entidade, sem id local', () {
      final Map<String, dynamic> json = LocacaoVeiculo(
        99.9,
        5,
        id: 42,
      ).toJson();
      expect(json, {'numeroContrato': 5, 'valorLocacao': 99.9});
    });

    test('fromJson aceita inteiros e marca como sincronizado', () {
      final LocacaoVeiculo locacao = LocacaoVeiculo.fromJson({
        'id': 10,
        'numeroContrato': 2001,
        'valorLocacao': 500,
      });
      expect(locacao.valorLocacao, 500.0);
      expect(locacao.numeroContrato, 2001);
      expect(locacao.sincronizado, isTrue);
    });
  });
}
