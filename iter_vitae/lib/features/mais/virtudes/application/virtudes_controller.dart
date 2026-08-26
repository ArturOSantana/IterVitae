import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/virtue.dart';
import '../../../../providers.dart';
import '../../../hoje/application/hoje_controller.dart';

/// Estado da tela Virtudes em Foco.
class VirtudesState {
  const VirtudesState({
    required this.virtues,
    this.current,
  });

  /// Todas as virtudes (mais recente primeiro).
  final List<Virtue> virtues;

  /// Virtude atualmente em foco (null se não configurada).
  final Virtue? current;

  /// Virtudes já encerradas (exclui a virtude ativa).
  List<Virtue> get history =>
      current == null ? virtues : virtues.where((v) => v.id != current!.id).toList();
}

/// Controller da tela Virtudes em Foco.
class VirtudesController extends AsyncNotifier<VirtudesState> {
  @override
  Future<VirtudesState> build() async {
    final repo = ref.read(virtueRepositoryProvider);
    final all = await repo.getAll();
    final current = await repo.getActiveVirtue();
    return VirtudesState(virtues: all, current: current);
  }

  /// Cria uma nova virtude em foco.
  ///
  /// Se já existe uma virtude ativa, ela é encerrada automaticamente.
  Future<void> novaVirtude(String nome, String proposito) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(virtueRepositoryProvider);
    final now = DateTime.now();

    // Encerra a virtude ativa atual, se houver
    if (current.current != null) {
      final encerrada = current.current!.copyWith(endDate: now);
      await repo.save(encerrada);
    }

    final nova = Virtue(
      id: 'virtue_${now.millisecondsSinceEpoch}',
      name: nome.trim(),
      startDate: now,
      purpose: proposito.trim(),
    );

    await repo.save(nova);

    // Recarrega
    final all = await repo.getAll();
    final active = await repo.getActiveVirtue();
    state = AsyncData(VirtudesState(virtues: all, current: active));
    ref.invalidate(hojeControllerProvider);
  }

  /// Edita nome e propósito da virtude ativa.
  Future<void> editarAtiva(String nome, String proposito) async {
    final current = state.valueOrNull;
    if (current?.current == null) return;

    final repo = ref.read(virtueRepositoryProvider);
    final atualizada = current!.current!.copyWith(
      name: nome.trim(),
      purpose: proposito.trim(),
    );

    await repo.save(atualizada);

    final all = await repo.getAll();
    final active = await repo.getActiveVirtue();
    state = AsyncData(VirtudesState(virtues: all, current: active));
    ref.invalidate(hojeControllerProvider);
  }

  /// Encerra a virtude ativa manualmente (sem iniciar outra).
  Future<void> encerrarAtiva() async {
    final current = state.valueOrNull;
    if (current?.current == null) return;

    final repo = ref.read(virtueRepositoryProvider);
    final encerrada = current!.current!.copyWith(endDate: DateTime.now());
    await repo.save(encerrada);

    final all = await repo.getAll();
    state = AsyncData(VirtudesState(virtues: all, current: null));
    ref.invalidate(hojeControllerProvider);
  }
}

/// Provider do [VirtudesController].
final virtudesControllerProvider =
    AsyncNotifierProvider<VirtudesController, VirtudesState>(
        VirtudesController.new);
