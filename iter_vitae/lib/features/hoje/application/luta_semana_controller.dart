import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/struggle.dart';
import '../../../providers.dart';
import '../../mais/exame/application/exame_diario_controller.dart'
    show startOfWeekFor;

/// Resumo de contagem por status para uma semana de logs de uma luta.
class LutaSemanaResumo {
  const LutaSemanaResumo({
    required this.inicio,
    required this.dias,
  });

  /// Primeiro dia (segunda-feira) da semana.
  final DateTime inicio;

  /// Lista de 7 posições (seg–dom); null = sem registro naquele dia.
  final List<DailyStruggleStatus?> dias;

  // ── Contagens ──────────────────────────────────────────────────────────────

  int get consegui =>
      dias.where((d) => d == DailyStruggleStatus.achieved).length;

  int get luteiECai =>
      dias.where((d) => d == DailyStruggleStatus.fought).length;

  int get naoLutei =>
      dias.where((d) => d == DailyStruggleStatus.didNotFight).length;

  int get semRegistro => dias.where((d) => d == null).length;
}

/// Estado retornado pelo [lutaSemanaProvider].
class LutaSemanaState {
  const LutaSemanaState({
    required this.struggle,
    required this.semanaAtual,
    required this.semanaAnterior,
  });

  final Struggle struggle;
  final LutaSemanaResumo semanaAtual;
  final LutaSemanaResumo semanaAnterior;
}

// ── Helpers internos ──────────────────────────────────────────────────────────

LutaSemanaResumo _buildResumo(Struggle struggle, DateTime startOfWeek) {
  return LutaSemanaResumo(
    inicio: startOfWeek,
    dias: List.generate(7, (i) {
      final dia = startOfWeek.add(Duration(days: i));
      final d = DateTime(dia.year, dia.month, dia.day);
      try {
        return struggle.dailyLogs
            .lastWhere(
              (l) => DateTime(l.date.year, l.date.month, l.date.day) == d,
            )
            .status;
      } on StateError {
        return null;
      }
    }),
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Carrega a luta ativa e monta o quadro comparativo das duas semanas.
/// Retorna null quando não há luta ativa.
final lutaSemanaProvider = FutureProvider<LutaSemanaState?>((ref) async {
  final struggle = await ref.read(struggleRepositoryProvider).getActive();
  if (struggle == null) return null;

  final hoje = DateTime.now();
  final inicioSemanaAtual = startOfWeekFor(hoje);
  final inicioSemanaAnterior =
      inicioSemanaAtual.subtract(const Duration(days: 7));

  return LutaSemanaState(
    struggle: struggle,
    semanaAtual: _buildResumo(struggle, inicioSemanaAtual),
    semanaAnterior: _buildResumo(struggle, inicioSemanaAnterior),
  );
});
