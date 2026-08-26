import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/practice_log.dart';
import '../../../domain/entities/reflection.dart';
import '../../../domain/entities/struggle.dart';
import '../../../providers.dart';
import 'hoje_state.dart';
import 'luta_semana_controller.dart';

/// Controller da tela Hoje.
///
/// Usa [AsyncNotifier] para expor o estado de carregamento.
/// Ações otimistas: [completePractice] e [markStruggle] atualizam
/// o estado antes de confirmar no repositório.
class HojeController extends AsyncNotifier<HojeState> {
  @override
  Future<HojeState> build() async {
    final today = DateTime.now();
    final practiceRepo = ref.read(practiceRepositoryProvider);
    final struggleRepo = ref.read(struggleRepositoryProvider);
    final virtueRepo = ref.read(virtueRepositoryProvider);

    final allActive = await practiceRepo.getActivePractices();

    // Filtra apenas as práticas agendadas para hoje (frequência e dia da semana)
    final practices = allActive.where((p) => p.isScheduledFor(today)).toList();

    // Carrega logs de hoje para cada prática do dia
    final logEntries = await Future.wait(
      practices.map((p) => practiceRepo.getLogForDate(p.id, today)),
    );
    final logs = <String, PracticeLog>{};
    for (var i = 0; i < practices.length; i++) {
      final log = logEntries[i];
      if (log != null) logs[practices[i].id] = log;
    }

    final activeStruggle = await struggleRepo.getActive();
    final currentVirtue = await virtueRepo.getActiveVirtue();

    return HojeState(
      date: today,
      practices: practices,
      logs: logs,
      activeStruggle: activeStruggle,
      currentVirtue: currentVirtue,
      todayReflection: null,
    );
  }

  // ── Completar prática ───────────────────────────────────────────────────

  /// Marca uma prática como concluída hoje com update otimista.
  Future<void> completePractice(String practiceId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final today = current.date;
    final logId = 'log_${practiceId}_${today.millisecondsSinceEpoch}';

    final newLog = PracticeLog(
      id: current.logs[practiceId]?.id ?? logId,
      practiceId: practiceId,
      date: today,
      completed: true,
    );

    // Update otimista — UI reflete antes do repositório confirmar
    final updatedLogs = Map<String, PracticeLog>.from(current.logs)
      ..[practiceId] = newLog;
    state = AsyncData(current.copyWith(logs: updatedLogs));

    // Persiste no repositório
    try {
      await ref.read(practiceRepositoryProvider).saveLog(newLog);
    } catch (_) {
      // Reverte em caso de erro
      final revertedLogs = Map<String, PracticeLog>.from(
        state.valueOrNull?.logs ?? {},
      )..remove(practiceId);
      state = AsyncData(current.copyWith(logs: revertedLogs));
    }
  }

  // ── Marcar estado da luta ──────────────────────────────────────────────

  /// Registra o estado diário da luta ativa com update otimista.
  Future<void> markStruggle(
    String struggleId,
    DailyStruggleStatus status,
  ) async {
    final current = state.valueOrNull;
    if (current == null || current.activeStruggle == null) return;

    final today = current.date;
    final newLog = DailyStruggleLog(date: today, status: status);

    // Atualiza a lista de logs no estado otimisticamente
    final d = DateTime(today.year, today.month, today.day);
    final updatedDailyLogs = current.activeStruggle!.dailyLogs
        .where(
          (l) => DateTime(l.date.year, l.date.month, l.date.day) != d,
        )
        .toList()
      ..add(newLog);

    final updatedStruggle =
        current.activeStruggle!.copyWith(dailyLogs: updatedDailyLogs);
    state = AsyncData(current.copyWith(activeStruggle: updatedStruggle));

    try {
      await ref
          .read(struggleRepositoryProvider)
          .logDaily(struggleId, newLog);
      ref.invalidate(lutaSemanaProvider);
    } catch (_) {
      // Reverte
      state = AsyncData(current);
    }
  }

  // ── Salvar reflexão ────────────────────────────────────────────────────

  /// Persiste a reflexão noturna de hoje.
  Future<void> saveReflection(String text) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final reflection = Reflection(
      id: current.todayReflection?.id ??
          'ref_${current.date.millisecondsSinceEpoch}',
      date: current.date,
      text: text,
    );

    state = AsyncData(current.copyWith(todayReflection: reflection));

    try {
      await ref.read(reflectionRepositoryProvider).save(reflection);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

/// Provider do [HojeController].
final hojeControllerProvider =
    AsyncNotifierProvider<HojeController, HojeState>(HojeController.new);
