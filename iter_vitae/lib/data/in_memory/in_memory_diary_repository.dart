import '../../domain/entities/diary_entry.dart';
import '../../domain/repositories/diary_repository.dart';

/// Implementação em memória do [DiaryRepository].
/// TODO: substituir por FirestoreDiaryRepository.
class InMemoryDiaryRepository implements DiaryRepository {
  final List<DiaryEntry> _entries = [];

  @override
  Future<List<DiaryEntry>> getAll() async {
    final sorted = List<DiaryEntry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  @override
  Future<List<DiaryEntry>> getForPeriod(DateTime from, DateTime to) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return _entries
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> save(DiaryEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }
}
