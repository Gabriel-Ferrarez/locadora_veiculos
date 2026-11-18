import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locadora_veiculos/main.dart';
import 'package:locadora_veiculos/models/locacao_veiculo.dart';
import 'package:locadora_veiculos/repository/locacao_repository.dart';

/// Repository em memória para testar as telas sem banco nem rede.
class RepositoryFalso implements LocacaoRepository {
  final List<LocacaoVeiculo> locacoes;
  bool apiIndisponivel;
  StatusCadastro statusCadastro;
  LocacaoVeiculo? ultimaCadastrada;
  int sincronizacoes = 0;

  RepositoryFalso(
    this.locacoes, {
    this.apiIndisponivel = false,
    this.statusCadastro = StatusCadastro.enviadoParaApi,
  });

  @override
  Future<StatusCadastro> cadastrar(LocacaoVeiculo locacao) async {
    ultimaCadastrada = locacao;
    locacoes.insert(
      0,
      locacao.copyWith(
        sincronizado: statusCadastro == StatusCadastro.enviadoParaApi,
      ),
    );
    return statusCadastro;
  }

  @override
  Future<ResultadoListagem> listar() async {
    return ResultadoListagem(
      List.of(locacoes),
      apiIndisponivel: apiIndisponivel,
    );
  }

  @override
  Future<ResultadoSincronizacao> sincronizarPendentes() async {
    sincronizacoes++;
    int enviados = 0;
    for (int i = 0; i < locacoes.length; i++) {
      if (!locacoes[i].sincronizado) {
        locacoes[i] = locacoes[i].copyWith(sincronizado: true);
        enviados++;
      }
    }
    apiIndisponivel = false;
    return ResultadoSincronizacao(enviados: enviados, restantes: 0);
  }

  @override
  Future<int> contarPendentes() async {
    return locacoes.where((l) => !l.sincronizado).length;
  }
}

Future<void> abrirLista(WidgetTester tester, RepositoryFalso repository) async {
  await tester.pumpWidget(LocadoraApp(repository: repository));
  await tester.tap(find.text('Locações'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista mostra os registros e o status de sincronização', (
    tester,
  ) async {
    await abrirLista(
      tester,
      RepositoryFalso([
        LocacaoVeiculo(350.00, 1001, sincronizado: true),
        LocacaoVeiculo(1280.50, 1002),
      ]),
    );

    expect(find.text('Contrato nº 1001'), findsOneWidget);
    expect(find.text('Contrato nº 1002'), findsOneWidget);
    expect(find.text('Sincronizada'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Sincronizar pendentes'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('avisa quando a API está indisponível', (tester) async {
    await abrirLista(
      tester,
      RepositoryFalso([LocacaoVeiculo(350.00, 1001)], apiIndisponivel: true),
    );

    expect(find.textContaining('API indisponível'), findsOneWidget);
  });

  testWidgets('cadastro com a API fora volta para a lista como pendente', (
    tester,
  ) async {
    final RepositoryFalso repository = RepositoryFalso(
      [],
      statusCadastro: StatusCadastro.salvoComoPendente,
    );
    await abrirLista(tester, repository);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '2000');
    await tester.enterText(find.byType(TextField).at(1), '1.500,50');
    await tester.tap(find.text('Registrar locação'));
    await tester.pumpAndSettle();

    expect(repository.ultimaCadastrada?.numeroContrato, 2000);
    expect(repository.ultimaCadastrada?.valorLocacao, 1500.50);
    expect(
      find.text('API indisponível: locação salva no aparelho como pendente.'),
      findsOneWidget,
    );
    expect(find.text('Contrato nº 2000'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
  });

  testWidgets('"Sincronizar pendentes" envia e atualiza a lista', (
    tester,
  ) async {
    final RepositoryFalso repository = RepositoryFalso([
      LocacaoVeiculo(1280.50, 1002),
    ]);
    await abrirLista(tester, repository);

    await tester.tap(find.text('Sincronizar pendentes'));
    await tester.pumpAndSettle();

    expect(repository.sincronizacoes, 1);
    expect(
      find.text('1 locação(ões) sincronizada(s) com a API.'),
      findsOneWidget,
    );
    expect(find.text('Pendente'), findsNothing);
    expect(find.text('Sincronizada'), findsOneWidget);
  });

  testWidgets('formulário valida os campos', (tester) async {
    await abrirLista(tester, RepositoryFalso([]));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar locação'));
    await tester.pump();

    expect(
      find.text('Informe um nº de contrato e um valor válidos.'),
      findsOneWidget,
    );
  });
}
