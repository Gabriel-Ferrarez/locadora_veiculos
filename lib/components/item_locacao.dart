import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/locacao_veiculo.dart';
import 'selo_sincronizacao.dart';

/// Linha da lista de locações: valor, contrato e status de sincronização.
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
        leading: Icon(
          Icons.directions_car,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(formato.format(_locacao.valorLocacao)),
        subtitle: Text('Contrato nº ${_locacao.numeroContrato}'),
        trailing: SeloSincronizacao(sincronizado: _locacao.sincronizado),
      ),
    );
  }
}
