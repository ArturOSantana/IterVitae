import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/struggle.dart';
import '../../../../providers.dart';
import '../../../hoje/application/hoje_controller.dart';

/// Estado da tela Lutas.
class LutasState {
  const LutasState({
    required this.struggles,
    this.active,
  });

  /// Todas as lutas (mais recente primeiro).
  final List<Struggle> struggles;

  /// Luta atualmente ativa (null se não houver).
  final Struggle? active;

  /// Lutas já encerradas.
  List<Struggle> get history =>
      active == null ? struggles : struggles.where((s) => s.id != active!.id).toList();
}

/// Controller da tela Lutas.
class LutasController extends AsyncNotifier<LutasState> {
  @override
  Future<LutasState> build() async {
    final repo = ref.watch(struggleRepositoryProvider);
    final all = await repo.getAll();
    final active = await repo.getActive();
    return LutasState(struggles: all, active: active);
  }

  /// Cria uma nova luta ativa. Encerra a atual, se houver.
  Future<void> novaLuta(String titulo) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(struggleRepositoryProvider);
    final now = DateTime.now();

    // Encerra a luta ativa atual, se houver
    if (current.active != null) {
      final encerrada = current.active!.copyWith(
        status: StruggleStatus.encerrada,
        endDate: now,
      );
      await repo.save(encerrada);
    }

    final nova = Struggle(
      id: 'struggle_${now.millisecondsSinceEpoch}',
      title: titulo.trim(),
      status: StruggleStatus.ativa,
      startDate: now,
    );

    await repo.save(nova);

    // Recarrega
    final all = await repo.getAll();
    final active = await repo.getActive();
    state = AsyncData(LutasState(struggles: all, active: active));
    ref.invalidate(hojeControllerProvider);
  }

  /// Edita o título da luta ativa.
  Future<void> editarAtiva(String titulo) async {
    final current = state.valueOrNull;
    if (current?.active == null) return;

    final repo = ref.read(struggleRepositoryProvider);
    final atualizada = current!.active!.copyWith(title: titulo.trim());
    await repo.save(atualizada);

    final all = await repo.getAll();
    final active = await repo.getActive();
    state = AsyncData(LutasState(struggles: all, active: active));
    ref.invalidate(hojeControllerProvider);
  }

  /// Encerra a luta ativa manualmente.
  Future<void> encerrarAtiva() async {
    final current = state.valueOrNull;
    if (current?.active == null) return;

    final repo = ref.read(struggleRepositoryProvider);
    final encerrada = current!.active!.copyWith(
      status: StruggleStatus.encerrada,
      endDate: DateTime.now(),
    );
    await repo.save(encerrada);

    final all = await repo.getAll();
    state = AsyncData(LutasState(struggles: all, active: null));
    ref.invalidate(hojeControllerProvider);
  }
}

/// Provider do [LutasController].
final lutasControllerProvider =
    AsyncNotifierProvider<LutasController, LutasState>(LutasController.new);
