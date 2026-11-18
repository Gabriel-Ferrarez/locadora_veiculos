/// Entidade principal do tema "Locadora de Veículos".
///
/// Os campos do 1º bimestre ([valorLocacao] e [numeroContrato]) continuam os
/// mesmos. No 2º bimestre a entidade ganhou:
/// - [id]: chave da linha no SQLite local;
/// - [sincronizado]: `true` quando o registro já está na API (PostgreSQL) e
///   `false` quando está pendente de sincronização.
class LocacaoVeiculo {
  final int? id;
  final double valorLocacao;
  final int numeroContrato;
  final bool sincronizado;

  LocacaoVeiculo(
    this.valorLocacao,
    this.numeroContrato, {
    this.id,
    this.sincronizado = false,
  });

  LocacaoVeiculo copyWith({int? id, bool? sincronizado}) {
    return LocacaoVeiculo(
      valorLocacao,
      numeroContrato,
      id: id ?? this.id,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  // ---------- SQLite (colunas em snake_case) ----------

  /// Linha da tabela `locacoes`. A coluna `sincronizado` guarda
  /// 1 (sincronizado) ou 0 (pendente), já que o SQLite não tem tipo booleano.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'valor_locacao': valorLocacao,
      'numero_contrato': numeroContrato,
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  factory LocacaoVeiculo.fromMap(Map<String, dynamic> map) {
    return LocacaoVeiculo(
      (map['valor_locacao'] as num).toDouble(),
      (map['numero_contrato'] as num).toInt(),
      id: map['id'] as int?,
      sincronizado: map['sincronizado'] == 1,
    );
  }

  // ---------- API (JSON em camelCase) ----------

  /// Corpo enviado no `POST /locacoes`. O id local não vai para a API:
  /// quem gera o id remoto é o PostgreSQL.
  Map<String, dynamic> toJson() {
    return {'numeroContrato': numeroContrato, 'valorLocacao': valorLocacao};
  }

  /// Registro vindo da API: por definição já está sincronizado.
  factory LocacaoVeiculo.fromJson(Map<String, dynamic> json) {
    return LocacaoVeiculo(
      (json['valorLocacao'] as num).toDouble(),
      (json['numeroContrato'] as num).toInt(),
      sincronizado: true,
    );
  }

  @override
  String toString() {
    return 'LocacaoVeiculo{id: $id, valorLocacao: $valorLocacao, '
        'numeroContrato: $numeroContrato, sincronizado: $sincronizado}';
  }
}
