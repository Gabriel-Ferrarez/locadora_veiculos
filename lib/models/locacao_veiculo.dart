class LocacaoVeiculo {
  final double valorLocacao;
  final int numeroContrato;

  LocacaoVeiculo(this.valorLocacao, this.numeroContrato);

  @override
  String toString() {
    return "LocacaoVeiculo{valorLocacao: $valorLocacao, numeroContrato: $numeroContrato}";
  }
}
