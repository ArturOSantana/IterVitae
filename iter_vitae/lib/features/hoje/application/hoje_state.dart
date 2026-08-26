import '../../../domain/entities/practice.dart';
import '../../../domain/entities/practice_log.dart';
import '../../../domain/entities/struggle.dart';
import '../../../domain/entities/virtue.dart';
import '../../../domain/entities/reflection.dart';

/// Estado imutável da tela Hoje.
class HojeState {
  const HojeState({
    required this.date,
    required this.practices,
    required this.logs,
    required this.activeStruggle,
    required this.currentVirtue,
    required this.todayReflection,
  });

  /// Data de referência (hoje).
  final DateTime date;

  /// Práticas ativas do plano.
  final List<Practice> practices;

  /// Logs das práticas para hoje. Índice: practiceId → PracticeLog.
  final Map<String, PracticeLog> logs;

  /// Luta espiritual ativa (null se não houver).
  final Struggle? activeStruggle;

  /// Virtude trabalhada no mês (null se não configurada).
  final Virtue? currentVirtue;

  /// Reflexão noturna de hoje (null se ainda não registrada).
  final Reflection? todayReflection;

  // ── Computed ─────────────────────────────────────────────────────────────

  /// Quantidade de práticas concluídas hoje.
  int get completedCount =>
      logs.values.where((l) => l.completed).length;

  /// Total de práticas do dia.
  int get totalCount => practices.length;

  /// Percentual de fidelidade hoje (0.0 – 1.0).
  double get progressRatio =>
      totalCount == 0 ? 0 : completedCount / totalCount;

  /// Verdadeiro quando todas as práticas do dia foram concluídas.
  bool get isAllComplete =>
      totalCount > 0 && completedCount == totalCount;

  /// Verdadeiro quando não há práticas configuradas para hoje.
  bool get isEmpty => practices.isEmpty;

  /// Log da luta para hoje, se houver.
  DailyStruggleLog? get todayStruggleLog {
    if (activeStruggle == null) return null;
    final today = DateTime(date.year, date.month, date.day);
    try {
      return activeStruggle!.dailyLogs.lastWhere(
        (l) => DateTime(l.date.year, l.date.month, l.date.day) == today,
      );
    } on StateError {
      return null;
    }
  }

  HojeState copyWith({
    DateTime? date,
    List<Practice>? practices,
    Map<String, PracticeLog>? logs,
    Struggle? activeStruggle,
    Virtue? currentVirtue,
    Reflection? todayReflection,
    bool clearStruggle = false,
    bool clearVirtue = false,
    bool clearReflection = false,
  }) {
    return HojeState(
      date: date ?? this.date,
      practices: practices ?? this.practices,
      logs: logs ?? this.logs,
      activeStruggle: clearStruggle ? null : activeStruggle ?? this.activeStruggle,
      currentVirtue: clearVirtue ? null : currentVirtue ?? this.currentVirtue,
      todayReflection: clearReflection ? null : todayReflection ?? this.todayReflection,
    );
  }
}
