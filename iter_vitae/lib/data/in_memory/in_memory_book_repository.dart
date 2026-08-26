import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

/// Implementação em memória do [BookRepository].
/// TODO: substituir por FirestoreBookRepository.
class InMemoryBookRepository implements BookRepository {
  InMemoryBookRepository() {
    _seedData();
  }

  final List<Book> _books = [];

  void _seedData() {
    final now = DateTime.now();
    _books.addAll([
      Book(
        id: 'b1',
        title: 'Imitação de Cristo',
        author: 'Tomás de Kempis',
        category: ReadingCategory.spiritual,
        status: BookStatus.reading,
        currentPage: 124,
        totalPages: 220,
        coverEmoji: '✝️',
        startedAt: now.subtract(const Duration(days: 18)),
      ),
      Book(
        id: 'b2',
        title: 'Meditações',
        author: 'Marco Aurélio',
        category: ReadingCategory.cultural,
        status: BookStatus.reading,
        currentPage: 67,
        totalPages: 180,
        coverEmoji: '🏛️',
        startedAt: now.subtract(const Duration(days: 10)),
      ),
      Book(
        id: 'b3',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        category: ReadingCategory.professional,
        status: BookStatus.wantToRead,
        currentPage: 0,
        totalPages: 431,
        coverEmoji: '💻',
      ),
    ]);
  }

  @override
  Future<List<Book>> getAll() async => List.unmodifiable(_books);

  @override
  Future<List<Book>> getByStatus(BookStatus status) async =>
      _books.where((b) => b.status == status).toList();

  @override
  Future<void> save(Book book) async {
    final idx = _books.indexWhere((b) => b.id == book.id);
    if (idx >= 0) {
      _books[idx] = book;
    } else {
      _books.add(book);
    }
  }
}
