import '../entities/book.dart';

/// Interface do repositório de livros.
/// TODO: implementar com Firestore em FirestoreBookRepository.
abstract interface class BookRepository {
  /// Retorna todos os livros da biblioteca.
  Future<List<Book>> getAll();

  /// Retorna livros filtrando por status.
  Future<List<Book>> getByStatus(BookStatus status);

  /// Salva (insere ou atualiza) um livro.
  Future<void> save(Book book);
}
