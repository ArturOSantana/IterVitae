import 'package:iter_vitae/domain/entities/book.dart';

/// Estado da tela principal de Leituras.
class ReadingsState {
  const ReadingsState({required this.books});

  final List<Book> books;

  /// Livros agrupados por categoria na ordem canônica.
  /// Apenas livros [BookStatus.reading] e [BookStatus.wantToRead] são incluídos
  /// (concluídos ficam ocultos por padrão — a tela pode expor um toggle depois).
  Map<ReadingCategory, List<Book>> get grouped {
    final result = <ReadingCategory, List<Book>>{};
    for (final cat in _categoryOrder) {
      final items = books
          .where((b) =>
              b.category == cat &&
              (b.status == BookStatus.reading ||
                  b.status == BookStatus.wantToRead))
          .toList()
        // reading primeiro, depois wantToRead; dentro de cada status, por título
        ..sort((a, b) {
          if (a.status != b.status) {
            return a.status == BookStatus.reading ? -1 : 1;
          }
          return a.title.compareTo(b.title);
        });
      if (items.isNotEmpty) result[cat] = items;
    }
    return result;
  }

  ReadingsState copyWith({List<Book>? books}) =>
      ReadingsState(books: books ?? this.books);
}

const _categoryOrder = [
  ReadingCategory.spiritual,
  ReadingCategory.cultural,
  ReadingCategory.professional,
];
