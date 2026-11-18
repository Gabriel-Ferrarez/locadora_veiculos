import 'package:flutter/material.dart';
import '../../components/editor.dart';
import '../../models/locacao_veiculo.dart';
import '../../repository/locacao_repository.dart';

class FormularioLocacao extends StatefulWidget {
  final LocacaoRepository repository;

  const FormularioLocacao({super.key, required this.repository});

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

  bool _enviando = false;

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
                onPressed: _enviando ? null : _criaLocacao,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_enviando ? 'Enviando...' : _textoBotaoConfirmar),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _criaLocacao() async {
    debugPrint("Botão registrar locação pressionado");
    final int? numeroContrato = int.tryParse(
      _controladorCampoNumeroContrato.text.trim(),
    );
    // Aceita vírgula como separador decimal (padrão brasileiro)
    final double? valorLocacao = double.tryParse(
      _controladorCampoValorLocacao.text
          .trim()
          .replaceAll('.', '')
          .replaceAll(',', '.'),
    );

    if (numeroContrato == null || valorLocacao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um nº de contrato e um valor válidos.'),
        ),
      );
      return;
    }

    final LocacaoVeiculo locacaoCriada = LocacaoVeiculo(
      valorLocacao,
      numeroContrato,
    );
    debugPrint('$locacaoCriada'); // Teste de saída no console

    setState(() => _enviando = true);
    try {
      // O repository decide: API, SQLite ou os dois (offline-first).
      final StatusCadastro status = await widget.repository.cadastrar(
        locacaoCriada,
      );
      if (!mounted) return;
      Navigator.pop(context, status);
    } catch (erro) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível registrar a locação: $erro')),
      );
    }
  }
}
