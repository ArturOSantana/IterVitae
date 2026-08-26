import '../../domain/entities/reflection.dart';
import '../../domain/repositories/reflection_repository.dart';

/// Implementação em memória do [ReflectionRepository].
/// TODO: substituir por FirestoreReflectionRepository.
class InMemoryReflectionRepository implements ReflectionRepository {
  final List<Reflection> _reflections = [];

  @override
  Future<Reflection?> getForDate(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    try {
      return _reflections.lastWhere(
        (r) => DateTime(r.date.year, r.date.month, r.date.day) == d,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<Reflection>> getForPeriod(DateTime from, DateTime to) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return _reflections.where((r) {
      return !r.date.isBefore(start) && !r.date.isAfter(end);
    }).toList();
  }

  @override
  Future<void> save(Reflection reflection) async {
    final index = _reflections.indexWhere((r) => r.id == reflection.id);
    if (index >= 0) {
      _reflections[index] = reflection;
    } else {
      _reflections.add(reflection);
    }
  }
}
