/// Uma sessão de leitura — log do que aconteceu em um momento de leitura.
///
/// Não é a fonte de cálculo do progresso do livro — [Book.currentPage] é
/// atualizado separadamente. A sessão é o registro narrativo do que aconteceu.
class ReadingSession {
  const ReadingSession({
    required this.id,
    required this.bookId,
    required this.date,
    this.startPage,
    this.pagesRead,
    this.minutesRead,
    this.highlight,
    this.application,
  });

  final String id;
  final String bookId;
  final DateTime date;

  /// Página inicial da sessão (opcional) — permite exibir o intervalo "pgs X–Y".
  final int? startPage;

  /// Páginas lidas nesta sessão (opcional).
  final int? pagesRead;

  /// Minutos de leitura (opcional).
  final int? minutesRead;

  /// O que me chamou atenção — opcional, texto livre.
  final String? highlight;

  /// O que posso aplicar — opcional, texto livre.
  final String? application;

  ReadingSession copyWith({
    String? id,
    String? bookId,
    DateTime? date,
    int? startPage,
    int? pagesRead,
    int? minutesRead,
    String? highlight,
    String? application,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      date: date ?? this.date,
      startPage: startPage ?? this.startPage,
      pagesRead: pagesRead ?? this.pagesRead,
      minutesRead: minutesRead ?? this.minutesRead,
      highlight: highlight ?? this.highlight,
      application: application ?? this.application,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ReadingSession && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
