/// Sessão de preparo para confissão.
///
/// Cada vez que o usuário inicia um novo preparo, uma sessão é criada.
/// A sessão guarda apenas quais itens foram marcados naquela ocasião —
/// não é um tracker de recorrência; é uma ferramenta de uso pontual.
class ExameConfissaoSessao {
  const ExameConfissaoSessao({
    required this.id,
    required this.date,
    this.itensMarcados = const [],
  });

  final String id;

  /// Data de início da sessão.
  final DateTime date;

  /// IDs dos [ExameConfissaoItem] marcados como "a examinar/confessar".
  final List<String> itensMarcados;

  ExameConfissaoSessao copyWith({
    String? id,
    DateTime? date,
    List<String>? itensMarcados,
  }) {
    return ExameConfissaoSessao(
      id: id ?? this.id,
      date: date ?? this.date,
      itensMarcados: itensMarcados ?? this.itensMarcados,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExameConfissaoSessao && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
