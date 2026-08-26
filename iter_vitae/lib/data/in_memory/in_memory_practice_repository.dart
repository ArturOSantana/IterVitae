import '../../domain/entities/practice.dart';
import '../../domain/entities/practice_log.dart';
import '../../domain/repositories/practice_repository.dart';

/// Implementação em memória do [PracticeRepository].
/// Usada apenas enquanto não há usuário autenticado (antes do login).
/// Sem dados mockados — a lista começa vazia; tudo que o usuário criar
/// existe somente durante a sessão atual do app.
class InMemoryPracticeRepository implements PracticeRepository {
  final List<Practice> _practices = [];
  final List<PracticeLog> _logs = [];

  @override
  Future<List<Practice>> getActivePractices() async {
    return _practices.where((p) => p.active).toList();
  }

  @override
  Future<List<Practice>> getAllPractices() async =>
      List.unmodifiable(_practices);

  @override
  Future<List<Practice>> getPracticesByCategory(
    PracticeCategory category,
  ) async {
    return _practices
        .where((p) => p.active && p.category == category)
        .toList();
  }

  @override
  Future<PracticeLog?> getLogForDate(String practiceId, DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    try {
      return _logs.lastWhere(
        (l) =>
            l.practiceId == practiceId &&
            DateTime(l.date.year, l.date.month, l.date.day) == d,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<PracticeLog>> getLogsForPeriod(
    DateTime from,
    DateTime to,
  ) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return _logs.where((l) {
      return !l.date.isBefore(start) && !l.date.isAfter(end);
    }).toList();
  }

  @override
  Future<void> saveLog(PracticeLog log) async {
    final index = _logs.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      _logs[index] = log;
    } else {
      _logs.add(log);
    }
  }

  @override
  Future<void> savePractice(Practice practice) async {
    final index = _practices.indexWhere((p) => p.id == practice.id);
    if (index >= 0) {
      _practices[index] = practice;
    } else {
      _practices.add(practice);
    }
  }

  @override
  Future<void> deactivatePractice(String practiceId) async {
    final index = _practices.indexWhere((p) => p.id == practiceId);
    if (index < 0) return;
    _practices[index] = _practices[index].copyWith(
      active: false,
      updatedAt: DateTime.now(),
    );
  }
}
