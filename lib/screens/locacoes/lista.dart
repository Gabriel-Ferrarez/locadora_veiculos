import 'package:flutter/material.dart';

import '../../components/item_locacao.dart';
import '../../components/selo_sincronizacao.dart';
import '../../models/locacao_veiculo.dart';
import '../../repository/locacao_repository.dart';
import 'formulario.dart';

class ListaLocacoes extends StatefulWidget {
  final LocacaoRepository repository;

  const ListaLocacoes({super.key, required this.repository});

  @override
  State<StatefulWidget> createState() {
    return ListaLocacoesState();
  }
}

class ListaLocacoesState extends State<ListaLocacoes> {
  static const _tituloAppBar = "Locações de Veículos";

  ResultadoListagem? _resultado;
  Object? _erro;
  bool _carregando = true;
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Pede a lista ao repository. A tela não sabe se os dados vieram da API
  /// ou do SQLite: só exibe o resultado.
  Future<void> _carregar() async {
    try {
      final ResultadoListagem resultado = await widget.repository.listar();
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _erro = null;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro;
        _carregando = false;
      });
    }
  }

  Future<void> _abrirFormulario() async {
    debugPrint("Botão + pressionado");
    final StatusCadastro? status = await Navigator.push<StatusCadastro>(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioLocacao(repository: widget.repository),
      ),
    );
    if (status == null || !mounted) return;

    switch (status) {
      case StatusCadastro.enviadoParaApi:
        _mostrarMensagem(
          'Locação registrada e enviada para a API.',
          SeloSincronizacao.corSincronizado,
        );
      case StatusCadastro.salvoComoPendente:
        _mostrarMensagem(
          'API indisponível: locação salva no aparelho como pendente.',
          SeloSincronizacao.corPendente,
        );
      case StatusCadastro.salvoLocalmente:
        _mostrarMensagem('Locação salva no aparelho.', null);
    }
    await _carregar();
  }

  Future<void> _sincronizar() async {
    setState(() => _sincronizando = true);
    try {
      final ResultadoSincronizacao resultado = await widget.repository
          .sincronizarPendentes();
      if (!mounted) return;

      if (resultado.apiIndisponivel) {
        _mostrarMensagem(
          resultado.enviados == 0
              ? 'API indisponível: as locações continuam pendentes. '
                    'Tente de novo quando a API voltar.'
              : 'A API caiu no meio da sincronização: '
                    '${resultado.enviados} enviada(s), '
                    '${resultado.restantes} continua(m) pendente(s).',
          SeloSincronizacao.corPendente,
        );
      } else if (resultado.enviados == 0) {
        _mostrarMensagem('Nenhuma locação pendente para sincronizar.', null);
      } else {
        _mostrarMensagem(
          '${resultado.enviados} locação(ões) sincronizada(s) com a API.',
          SeloSincronizacao.corSincronizado,
        );
      }
      await _carregar();
    } catch (erro) {
      if (mounted) {
        _mostrarMensagem('Não foi possível sincronizar: $erro', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  void _mostrarMensagem(String texto, Color? cor) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto), backgroundColor: cor));
  }

  @override
  Widget build(BuildContext context) {
    final int pendentes = _resultado?.totalPendentes ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(_tituloAppBar),
        actions: [
          IconButton(
            tooltip: 'Sincronizar pendentes',
            onPressed: _sincronizando ? null : _sincronizar,
            icon: _sincronizando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Badge(
                    isLabelVisible: pendentes > 0,
                    label: Text('$pendentes'),
                    child: const Icon(Icons.sync),
                  ),
          ),
        ],
      ),
      body: _corpo(),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final ResultadoListagem? resultado = _resultado;
    if (resultado == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Erro ao carregar locações.\n$_erro',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _carregando = true);
                  _carregar();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final List<LocacaoVeiculo> pendentes = resultado.locacoes
        .where((l) => !l.sincronizado)
        .toList();
    final List<LocacaoVeiculo> sincronizadas = resultado.locacoes
        .where((l) => l.sincronizado)
        .toList();

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Espaço no fim para o botão flutuante não cobrir o último item.
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
        children: [
          if (resultado.apiIndisponivel) const _AvisoApiIndisponivel(),
          if (resultado.locacoes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Nenhuma locação cadastrada.')),
            ),
          if (pendentes.isNotEmpty) ...[
            _CabecalhoPendentes(
              quantidade: pendentes.length,
              sincronizando: _sincronizando,
              onSincronizar: _sincronizar,
            ),
            ...pendentes.map(ItemLocacao.new),
          ],
          if (sincronizadas.isNotEmpty) ...[
            _CabecalhoSecao(
              'Sincronizadas com a API (${sincronizadas.length})',
            ),
            ...sincronizadas.map(ItemLocacao.new),
          ],
        ],
      ),
    );
  }
}

class _AvisoApiIndisponivel extends StatelessWidget {
  const _AvisoApiIndisponivel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SeloSincronizacao.corPendente.withValues(alpha: 0.1),
        border: Border.all(color: SeloSincronizacao.corPendente),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, color: SeloSincronizacao.corPendente),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'API indisponível. Exibindo as locações salvas no aparelho; '
              'novos cadastros ficam pendentes.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CabecalhoPendentes extends StatelessWidget {
  final int quantidade;
  final bool sincronizando;
  final VoidCallback onSincronizar;

  const _CabecalhoPendentes({
    required this.quantidade,
    required this.sincronizando,
    required this.onSincronizar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Pendentes de sincronização ($quantidade)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: SeloSincronizacao.corPendente,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: sincronizando ? null : onSincronizar,
            icon: const Icon(Icons.sync),
            label: const Text('Sincronizar pendentes'),
          ),
        ],
      ),
    );
  }
}

class _CabecalhoSecao extends StatelessWidget {
  final String texto;

  const _CabecalhoSecao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
