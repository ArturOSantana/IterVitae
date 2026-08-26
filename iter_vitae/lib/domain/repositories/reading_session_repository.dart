import '../entities/reading_session.dart';

/// Interface do repositório de sessões de leitura.
/// TODO: implementar com Firestore em FirestoreReadingSessionRepository.
abstract interface class ReadingSessionRepository {
  /// Retorna todas as sessões de um livro, ordenadas por data (mais recente primeiro).
  Future<List<ReadingSession>> getForBook(String bookId);

  /// Retorna sessões em um período — usado pelo [DirectionController] no bloco b.
  Future<List<ReadingSession>> getForPeriod(DateTime from, DateTime to);

  /// Salva (insere ou atualiza) uma sessão.
  Future<void> save(ReadingSession session);
}
