import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/spiritual_direction.dart';
import '../../../providers.dart';

/// Controller que carrega todas as direções já realizadas, ordenadas
/// da mais recente para a mais antiga.
class DirectionHistoryController
    extends AsyncNotifier<List<SpiritualDirection>> {
  @override
  Future<List<SpiritualDirection>> build() async {
    final repo = ref.watch(directionRepositoryProvider);
    final all = await repo.getAll();

    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);

    // Somente as que já ocorreram (date < hoje)
    final past = all
        .where((d) => d.date.isBefore(today0))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // mais recente primeiro

    return past;
  }

  /// Invalida o histórico para que seja recarregado.
  void refresh() => ref.invalidateSelf();
}

/// Provider do [DirectionHistoryController].
final directionHistoryControllerProvider =
    AsyncNotifierProvider<DirectionHistoryController, List<SpiritualDirection>>(
  DirectionHistoryController.new,
);
