import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iter_vitae/domain/entities/practice.dart';
import 'package:iter_vitae/providers.dart';
import '../../hoje/application/hoje_controller.dart';
import 'life_plan_state.dart';

/// Controller da tela Regra de Vida.
class LifePlanController extends AsyncNotifier<LifePlanState> {
  @override
  Future<LifePlanState> build() async {
    final repo = ref.read(practiceRepositoryProvider);
    final practices = await repo.getAllPractices();
    return LifePlanState(practices: practices);
  }

  /// Salva uma prática nova ou editada.
  /// Gera um id único para práticas novas (id vazio).
  ///
  /// Relança a exceção após reverter o update otimista, para que a tela
  /// possa exibir um aviso ao usuário em vez de falhar silenciosamente.
  Future<void> savePractice(Practice practice) async {
    final now = DateTime.now();
    final toSave = practice.id.isEmpty
        ? practice.copyWith(
            id: 'p_${now.millisecondsSinceEpoch}',
            updatedAt: now,
          )
        : practice.copyWith(updatedAt: now);

    // Update otimista
    final current = state.valueOrNull;
    if (current != null) {
      final updated = List<Practice>.from(current.practices);
      final idx = updated.indexWhere((p) => p.id == toSave.id);
      if (idx >= 0) {
        updated[idx] = toSave;
      } else {
        updated.add(toSave);
      }
      state = AsyncData(current.copyWith(practices: updated));
    }

    try {
      await ref.read(practiceRepositoryProvider).savePractice(toSave);
      ref.invalidate(hojeControllerProvider);
    } catch (e) {
      // Reverte em caso de erro e propaga para a UI poder avisar o usuário
      if (current != null) state = AsyncData(current);
      rethrow;
    }
  }

  /// Desativa uma prática.
  /// Entra em vigor no dia seguinte — não remove dos logs do dia atual.
  Future<void> deactivatePractice(String practiceId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final now = DateTime.now();
    final updated = current.practices.map((p) {
      return p.id == practiceId
          ? p.copyWith(active: false, updatedAt: now)
          : p;
    }).toList();

    state = AsyncData(current.copyWith(practices: updated));

    try {
      await ref.read(practiceRepositoryProvider).deactivatePractice(practiceId);
      ref.invalidate(hojeControllerProvider);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final lifePlanControllerProvider =
    AsyncNotifierProvider<LifePlanController, LifePlanState>(
  LifePlanController.new,
);
