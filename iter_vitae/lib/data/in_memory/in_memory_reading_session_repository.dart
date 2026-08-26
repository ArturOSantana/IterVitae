import '../../domain/entities/reading_session.dart';
import '../../domain/repositories/reading_session_repository.dart';

/// Implementação em memória do [ReadingSessionRepository].
/// TODO: substituir por FirestoreReadingSessionRepository.
class InMemoryReadingSessionRepository implements ReadingSessionRepository {
  InMemoryReadingSessionRepository() {
    _seedData();
  }

  final List<ReadingSession> _sessions = [];

  void _seedData() {
    final now = DateTime.now();
    _sessions.addAll([
      ReadingSession(
        id: 'rs1',
        bookId: 'b1',
        date: now.subtract(const Duration(days: 3)),
        startPage: 1,
        pagesRead: 20,
        minutesRead: 25,
        highlight: 'Capítulo sobre a humildade: "Que aproveita ao homem discutir profundamente sobre a Trindade?"',
        application: 'Reduzir o tempo em debates intelectuais que não edificam.',
      ),
      ReadingSession(
        id: 'rs2',
        bookId: 'b1',
        date: now.subtract(const Duration(days: 1)),
        startPage: 21,
        pagesRead: 15,
        minutesRead: 20,
        highlight: 'A paz interior não vem das coisas externas.',
      ),
    ]);
  }

  @override
  Future<List<ReadingSession>> getForBook(String bookId) async {
    final result = _sessions
        .where((s) => s.bookId == bookId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  @override
  Future<List<ReadingSession>> getForPeriod(
    DateTime from,
    DateTime to,
  ) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return _sessions
        .where((s) => !s.date.isBefore(start) && !s.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> save(ReadingSession session) async {
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      _sessions[idx] = session;
    } else {
      _sessions.add(session);
    }
  }
}
