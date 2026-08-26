import '../../domain/entities/virtue.dart';
import '../../domain/repositories/virtue_repository.dart';

/// Implementação em memória do [VirtueRepository].
/// TODO: substituir por FirestoreVirtueRepository.
class InMemoryVirtueRepository implements VirtueRepository {
  final List<Virtue> _virtues = [];

  @override
  Future<Virtue?> getActiveVirtue() async {
    try {
      return _virtues.lastWhere((v) => v.isActive);
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<Virtue>> getAll() async {
    return List<Virtue>.from(_virtues)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  @override
  Future<void> save(Virtue virtue) async {
    final index = _virtues.indexWhere((v) => v.id == virtue.id);
    if (index >= 0) {
      _virtues[index] = virtue;
    } else {
      _virtues.add(virtue);
    }
  }
}
