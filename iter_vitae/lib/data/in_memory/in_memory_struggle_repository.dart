import '../../domain/entities/struggle.dart';
import '../../domain/repositories/struggle_repository.dart';

/// Implementação em memória do [StruggleRepository].
/// TODO: substituir por FirestoreStruggleRepository.
class InMemoryStruggleRepository implements StruggleRepository {
  final List<Struggle> _struggles = [];

  @override
  Future<Struggle?> getActive() async {
    try {
      return _struggles.lastWhere(
        (s) => s.status == StruggleStatus.ativa,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<Struggle>> getAll() async => List.unmodifiable(_struggles);

  @override
  Future<void> save(Struggle struggle) async {
    final index = _struggles.indexWhere((s) => s.id == struggle.id);
    if (index >= 0) {
      _struggles[index] = struggle;
    } else {
      _struggles.add(struggle);
    }
  }

  @override
  Future<void> logDaily(String struggleId, DailyStruggleLog log) async {
    final index = _struggles.indexWhere((s) => s.id == struggleId);
    if (index < 0) return;

    final struggle = _struggles[index];
    final d = DateTime(log.date.year, log.date.month, log.date.day);

    // Remove log existente do mesmo dia, se houver
    final updatedLogs = struggle.dailyLogs
        .where((l) =>
            DateTime(l.date.year, l.date.month, l.date.day) != d)
        .toList()
      ..add(log);

    _struggles[index] = struggle.copyWith(dailyLogs: updatedLogs);
  }
}
