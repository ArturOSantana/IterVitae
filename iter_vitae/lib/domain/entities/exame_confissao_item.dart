/// Um item do catálogo fixo de exame para confissão.
///
/// O catálogo é seed data — não editável pelo usuário.
/// Cada item pertence a uma [categoria] (ex.: "Primeiro mandamento")
/// e contém um [texto] com a pergunta de exame.
class ExameConfissaoItem {
  const ExameConfissaoItem({
    required this.id,
    required this.categoria,
    required this.texto,
    required this.ordem,
  });

  /// Identificador único (ex.: "cmd1_1").
  final String id;

  /// Categoria/grupo ao qual pertence (ex.: "Primeiro mandamento").
  final String categoria;

  /// Pergunta ou enunciado de exame.
  final String texto;

  /// Posição de exibição dentro da categoria.
  final int ordem;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExameConfissaoItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
