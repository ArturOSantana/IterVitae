/// Entrada do Diário — escrita livre, não vinculada a nenhuma prática.
///
/// É o único lugar do app para temas sensíveis: texto livre,
/// nunca pergunta estruturada com escala.
///
/// [tags] é uma lista opcional de marcadores (ex.: ['#meios', '#retiro']).
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.date,
    required this.text,
    this.tags = const [],
  });

  final String id;
  final DateTime date;

  /// Texto livre — sem título obrigatório, sem campos estruturados.
  final String text;

  /// Marcadores opcionais para categorização (ex.: '#meios').
  final List<String> tags;

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? text,
    List<String>? tags,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      text: text ?? this.text,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DiaryEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
