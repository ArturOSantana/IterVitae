import '../../domain/entities/spiritual_direction.dart';
import '../../domain/repositories/direction_repository.dart';

/// Implementação em memória do [DirectionRepository].
/// Mock: uma direção passada (há 45 dias) e uma futura (daqui a 8 dias).
/// Isso permite testar o período de agregação sem valor fixo de "30 dias".
/// TODO: substituir por FirestoreDirectionRepository.
class InMemoryDirectionRepository implements DirectionRepository {
  InMemoryDirectionRepository() {
    _seedData();
  }

  final List<SpiritualDirection> _directions = [];

  void _seedData() {
    final today = DateTime.now();

    _directions.addAll([
      // Direção passada — define o início do período de agregação
      SpiritualDirection(
        id: 'dir_past',
        date: today.subtract(const Duration(days: 45)),
        directorName: 'Pe. Angel',
        nextDate: today.add(const Duration(days: 8)),
      ),
      // Próxima direção — é aqui que as notas de preparação são salvas
      SpiritualDirection(
        id: 'dir_next',
        date: today.add(const Duration(days: 8)),
        directorName: 'Pe. Angel',
      ),
    ]);
  }

  @override
  Future<List<SpiritualDirection>> getAll() async =>
      List.unmodifiable(_directions);

  @override
  Future<SpiritualDirection?> getLastPast() async {
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);

    final past = _directions
        .where((d) => d.date.isBefore(today0))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return past.isEmpty ? null : past.first;
  }

  @override
  Future<SpiritualDirection> getOrCreateNext() async {
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);

    final futures = _directions
        .where((d) => !d.date.isBefore(today0))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (futures.isNotEmpty) return futures.first;

    // Não existe próxima direção — cria uma em branco
    final newDirection = SpiritualDirection(
      id: 'dir_${today.millisecondsSinceEpoch}',
      date: today.add(const Duration(days: 30)),
    );
    _directions.add(newDirection);
    return newDirection;
  }

  @override
  Future<void> save(SpiritualDirection direction) async {
    final index = _directions.indexWhere((d) => d.id == direction.id);
    if (index >= 0) {
      _directions[index] = direction;
    } else {
      _directions.add(direction);
    }
  }
}
