import '../database/locacao_dao.dart';
import '../models/locacao_veiculo.dart';
import 'locacao_repository.dart';

/// Estratégia de persistência local: tudo fica só no SQLite do aparelho.
///
/// Os registros são gravados como pendentes (0), porque nunca foram enviados
/// à API. Se o app passar a usar a estratégia offline-first, eles podem ser
/// enviados depois com "Sincronizar pendentes".
class LocacaoRepositoryLocal implements LocacaoRepository {
  final LocacaoDao _dao;

  LocacaoRepositoryLocal({LocacaoDao? dao}) : _dao = dao ?? LocacaoDao();

  @override
  Future<StatusCadastro> cadastrar(LocacaoVeiculo locacao) async {
    await _dao.salvar(locacao.copyWith(sincronizado: false));
    return StatusCadastro.salvoLocalmente;
  }

  @override
  Future<ResultadoListagem> listar() async {
    return ResultadoListagem(await _dao.buscarTodas());
  }

  /// Sem API nesta estratégia: não há o que sincronizar.
  @override
  Future<ResultadoSincronizacao> sincronizarPendentes() async {
    return ResultadoSincronizacao(
      enviados: 0,
      restantes: await _dao.contarPendentes(),
    );
  }

  @override
  Future<int> contarPendentes() => _dao.contarPendentes();
}
