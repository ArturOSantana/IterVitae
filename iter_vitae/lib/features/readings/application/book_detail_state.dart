import 'package:iter_vitae/domain/entities/book.dart';
import 'package:iter_vitae/domain/entities/reading_session.dart';

/// Estado da tela de detalhe de um livro.
class BookDetailState {
  const BookDetailState({
    required this.book,
    required this.sessions,
  });

  final Book book;

  /// Sessões ordenadas por data (mais recente primeiro).
  final List<ReadingSession> sessions;

  BookDetailState copyWith({Book? book, List<ReadingSession>? sessions}) =>
      BookDetailState(
        book: book ?? this.book,
        sessions: sessions ?? this.sessions,
      );
}
