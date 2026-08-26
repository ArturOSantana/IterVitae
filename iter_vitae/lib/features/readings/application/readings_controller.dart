import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iter_vitae/domain/entities/book.dart';
import 'package:iter_vitae/providers.dart';
import 'readings_state.dart';

/// Controller da tela principal de Leituras.
class ReadingsController extends AsyncNotifier<ReadingsState> {
  @override
  Future<ReadingsState> build() async {
    final books = await ref.watch(bookRepositoryProvider).getAll();
    return ReadingsState(books: books);
  }

  /// Salva um livro novo ou editado.
  Future<void> saveBook(Book book) async {
    final now = DateTime.now();
    final toSave = book.id.isEmpty
        ? book.copyWith(id: 'b_${now.millisecondsSinceEpoch}')
        : book;

    final current = state.valueOrNull;
    if (current != null) {
      final updated = List<Book>.from(current.books);
      final idx = updated.indexWhere((b) => b.id == toSave.id);
      if (idx >= 0) {
        updated[idx] = toSave;
      } else {
        updated.add(toSave);
      }
      state = AsyncData(current.copyWith(books: updated));
    }

    try {
      await ref.read(bookRepositoryProvider).save(toSave);
    } catch (_) {
      if (current != null) state = AsyncData(current);
    }
  }
}

final readingsControllerProvider =
    AsyncNotifierProvider<ReadingsController, ReadingsState>(
  ReadingsController.new,
);
