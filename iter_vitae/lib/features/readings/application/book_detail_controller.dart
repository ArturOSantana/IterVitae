import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iter_vitae/domain/entities/book.dart';
import 'package:iter_vitae/domain/entities/reading_session.dart';
import 'package:iter_vitae/providers.dart';
import 'book_detail_state.dart';

/// Controller da tela de detalhe de um livro.
/// Recebe o [bookId] via [family].
class BookDetailController
    extends FamilyAsyncNotifier<BookDetailState, String> {
  @override
  Future<BookDetailState> build(String bookId) async {
    final books = await ref.read(bookRepositoryProvider).getAll();
    final book = books.firstWhere((b) => b.id == bookId);
    final sessions =
        await ref.read(readingSessionRepositoryProvider).getForBook(bookId);
    return BookDetailState(book: book, sessions: sessions);
  }

  /// Salva uma sessão de leitura e atualiza [Book.currentPage].
  Future<void> saveSession(ReadingSession session, int newCurrentPage) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedBook = current.book.copyWith(
      currentPage: newCurrentPage,
      // Se ainda não tinha startedAt, marca agora
      startedAt: current.book.startedAt ?? session.date,
      // Garante status reading ao registrar uma sessão
      status: current.book.status == BookStatus.wantToRead
          ? BookStatus.reading
          : current.book.status,
    );

    final updatedSessions = [session, ...current.sessions];
    state = AsyncData(current.copyWith(
      book: updatedBook,
      sessions: updatedSessions,
    ));

    try {
      await ref.read(readingSessionRepositoryProvider).save(session);
      await ref.read(bookRepositoryProvider).save(updatedBook);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  /// Marca o livro como concluído.
  Future<void> markFinished() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final now = DateTime.now();
    final updatedBook = current.book.copyWith(
      status: BookStatus.finished,
      finishedAt: now,
    );
    state = AsyncData(current.copyWith(book: updatedBook));

    try {
      await ref.read(bookRepositoryProvider).save(updatedBook);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

final bookDetailControllerProvider = AsyncNotifierProviderFamily<
    BookDetailController, BookDetailState, String>(
  BookDetailController.new,
);
