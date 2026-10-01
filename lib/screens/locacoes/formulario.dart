import 'package:flutter/material.dart';
import '../../components/editor.dart';
import '../../models/locacao_veiculo.dart';

class FormularioLocacao extends StatefulWidget {
  const FormularioLocacao({super.key});

  @override
  State<StatefulWidget> createState() {
    return FormularioLocacaoState();
  }
}

class FormularioLocacaoState extends State<FormularioLocacao> {
  final TextEditingController _controladorCampoNumeroContrato =
      TextEditingController();
  final TextEditingController _controladorCampoValorLocacao =
      TextEditingController();

  static const _tituloAppBar = 'Nova locação de veículo';
  static const _rotuloCampoValorLocacao = 'Valor da locação (R\$)';
  static const _dicaCampoValorLocacao = '0,00';

  static const _rotuloCampoNumeroContrato = 'Nº do contrato';
  static const _dicaCampoNumeroContrato = '0000';
  static const _textoBotaoConfirmar = 'Registrar locação';

  @override
  void dispose() {
    _controladorCampoNumeroContrato.dispose();
    _controladorCampoValorLocacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_tituloAppBar)),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.directions_car, size: 72),
            ),

            Editor(
              controlador: _controladorCampoNumeroContrato,
              rotulo: _rotuloCampoNumeroContrato,
              dica: _dicaCampoNumeroContrato,
              icone: Icons.description,
            ),

            Editor(
              controlador: _controladorCampoValorLocacao,
              rotulo: _rotuloCampoValorLocacao,
              dica: _dicaCampoValorLocacao,
              icone: Icons.attach_money,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint("Botão registrar locação pressionado");
                  _criaLocacao(
                    context,
                    _controladorCampoNumeroContrato,
                    _controladorCampoValorLocacao,
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text(_textoBotaoConfirmar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _criaLocacao(
  BuildContext context,
  TextEditingController controladorCampoNumeroContrato,
  TextEditingController controladorCampoValorLocacao,
) {
  final int? numeroContrato = int.tryParse(controladorCampoNumeroContrato.text);
  // Aceita vírgula como separador decimal (padrão brasileiro)
  final double? valorLocacao = double.tryParse(
    controladorCampoValorLocacao.text.replaceAll('.', '').replaceAll(',', '.'),
  );

  if (numeroContrato != null && valorLocacao != null) {
    final locacaoCriada = LocacaoVeiculo(valorLocacao, numeroContrato);

    debugPrint('$locacaoCriada'); // Teste de saída no console

    Navigator.pop(context, locacaoCriada);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Informe um nº de contrato e um valor válidos.'),
      ),
    );
  }
}
