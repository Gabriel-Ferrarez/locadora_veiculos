import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/locacao_veiculo.dart';
import 'formulario.dart';

class ListaLocacoes extends StatefulWidget {
  // Dados mantidos somente em memória (sem persistência)
  final List<LocacaoVeiculo> _locacoes = [
    LocacaoVeiculo(350.00, 1001),
    LocacaoVeiculo(1280.50, 1002),
  ];

  ListaLocacoes({super.key});

  @override
  State<StatefulWidget> createState() {
    return ListaLocacoesState();
  }
}

class ListaLocacoesState extends State<ListaLocacoes> {
  static const _tituloAppBar = "Locações de Veículos";

  Future<void> _atualiza(LocacaoVeiculo? locacaoRecebida) async {
    if (locacaoRecebida != null) {
      // Aguarda 1 segundo antes de exibir o novo item na lista
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        widget._locacoes.add(locacaoRecebida);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_tituloAppBar)),
      body: ListView.builder(
        itemCount: widget._locacoes.length,
        itemBuilder: (context, indice) {
          final locacao = widget._locacoes[indice];
          return ItemLocacao(locacao);
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint("Botão + pressionado");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const FormularioLocacao();
              },
            ),
          ).then((locacaoRecebida) => _atualiza(locacaoRecebida));
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ItemLocacao extends StatelessWidget {
  final LocacaoVeiculo _locacao;

  const ItemLocacao(this._locacao, {super.key});

  @override
  Widget build(BuildContext context) {
    final NumberFormat formato = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car),
        title: Text(formato.format(_locacao.valorLocacao)),
        subtitle: Text('Contrato nº ${_locacao.numeroContrato}'),
      ),
    );
  }
}
