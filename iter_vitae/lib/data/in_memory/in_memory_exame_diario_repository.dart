import '../../domain/entities/exame_diario.dart';
import '../../domain/repositories/exame_diario_repository.dart';

/// Implementação em memória do [ExameDiarioRepository].
/// TODO: substituir por FirestoreExameDiarioRepository.
class InMemoryExameDiarioRepository implements ExameDiarioRepository {
  final List<ExameDiario> _records = [];

  @override
  Future<ExameDiario?> getForDate(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    try {
      return _records.lastWhere(
        (e) => DateTime(e.date.year, e.date.month, e.date.day) == d,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<ExameDiario>> getWeek(DateTime startOfWeek) async {
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 6));
    return _records.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  @override
  Future<void> save(ExameDiario exame) async {
    final index = _records.indexWhere((e) => e.id == exame.id);
    if (index >= 0) {
      _records[index] = exame;
    } else {
      _records.add(exame);
    }
  }
}
