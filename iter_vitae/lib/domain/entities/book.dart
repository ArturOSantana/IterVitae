/// Categoria de um livro na biblioteca pessoal.
/// Enum separado de [PracticeCategory] — as semânticas são distintas.
enum ReadingCategory {
  spiritual,    // espiritual
  cultural,     // literatura, filosofia, história
  professional, // tecnologia, carreira, formação profissional
}

/// Status de leitura de um livro.
/// Sempre definido manualmente pelo usuário — nunca inferido por % de páginas.
enum BookStatus {
  wantToRead, // quero ler
  reading,    // lendo
  finished,   // concluído
}

/// Um livro da biblioteca pessoal.
///
/// [currentPage] é o estado atual do progresso, atualizado diretamente
/// (não calculado somando sessões). Separa a responsabilidade de "onde estou"
/// da responsabilidade de "o que aconteceu em cada sessão".
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    this.author,
    this.currentPage = 0,
    this.totalPages = 0,
    this.coverEmoji = '📖',
    this.notes,
    this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String title;
  final String? author;
  final ReadingCategory category;
  final BookStatus status;

  /// Página atual — estado direto, não derivado de sessões.
  final int currentPage;

  /// Total de páginas (0 = não informado).
  final int totalPages;

  /// Emoji de capa (mesmo padrão de [Practice.emoji]).
  final String coverEmoji;

  /// Nota geral sobre o livro (não sobre uma sessão específica).
  final String? notes;

  final DateTime? startedAt;

  /// Definido quando o usuário marca o livro como concluído — nunca automático.
  final DateTime? finishedAt;

  /// Progresso de leitura (0.0 – 1.0).
  /// Retorna 0 quando [totalPages] == 0 para evitar divisão por zero.
  double get progressRatio =>
      totalPages == 0 ? 0 : (currentPage / totalPages).clamp(0.0, 1.0);

  Book copyWith({
    String? id,
    String? title,
    String? author,
    ReadingCategory? category,
    BookStatus? status,
    int? currentPage,
    int? totalPages,
    String? coverEmoji,
    String? notes,
    DateTime? startedAt,
    DateTime? finishedAt,
    bool clearFinishedAt = false,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      coverEmoji: coverEmoji ?? this.coverEmoji,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: clearFinishedAt ? null : finishedAt ?? this.finishedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Book && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
