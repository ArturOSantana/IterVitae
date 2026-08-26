import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/exame_diario.dart';
import '../../../../domain/entities/practice.dart';
import '../../../../providers.dart';

// ── Estado ────────────────────────────────────────────────────────────────────

/// Resumo de uma prática para exibição no passo 3 do exame.
class PraticaResumo {
  const PraticaResumo({
    required this.nome,
    required this.categoria,
    required this.concluida,
  });

  final String nome;
  final PracticeCategory categoria;
  final bool concluida;
}

/// Estado do Exame Diário de Consciência.
class ExameDiarioState {
  const ExameDiarioState({
    required this.date,
    this.gratidao = '',
    this.revisaoDia = '',
    this.arrependimento = '',
    this.proposito = '',
    this.praticasHoje = const [],
    this.isSaved = false,
    this.isSaving = false,
  });

  final DateTime date;

  /// Passo 1 — gratidão.
  final String gratidao;

  /// Passo 3 — revisão do dia (texto livre).
  final String revisaoDia;

  /// Passo 4 — arrependimento.
  final String arrependimento;

  /// Passo 5 — propósito para amanhã.
  final String proposito;

  /// Resumo das práticas do dia, exibido automaticamente no passo 3.
  final List<PraticaResumo> praticasHoje;

  /// Exame já salvo hoje.
  final bool isSaved;

  final bool isSaving;

  ExameDiarioState copyWith({
    DateTime? date,
    String? gratidao,
    String? revisaoDia,
    String? arrependimento,
    String? proposito,
    List<PraticaResumo>? praticasHoje,
    bool? isSaved,
    bool? isSaving,
  }) {
    return ExameDiarioState(
      date: date ?? this.date,
      gratidao: gratidao ?? this.gratidao,
      revisaoDia: revisaoDia ?? this.revisaoDia,
      arrependimento: arrependimento ?? this.arrependimento,
      proposito: proposito ?? this.proposito,
      praticasHoje: praticasHoje ?? this.praticasHoje,
      isSaved: isSaved ?? this.isSaved,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class ExameDiarioController extends AsyncNotifier<ExameDiarioState> {
  @override
  Future<ExameDiarioState> build() async {
    final today = DateTime.now();
    final practiceRepo = ref.watch(practiceRepositoryProvider);
    final exameRepo = ref.watch(exameDiarioRepositoryProvider);

    // Carrega práticas ativas e seus logs de hoje
    final practices = await practiceRepo.getActivePractices();
    final logEntries = await Future.wait(
      practices.map((p) => practiceRepo.getLogForDate(p.id, today)),
    );
    final praticasResumo = <PraticaResumo>[];
    for (var i = 0; i < practices.length; i++) {
      final p = practices[i];
      final log = logEntries[i];
      // Exibe apenas práticas agendadas para hoje
      if (p.isScheduledFor(today)) {
        praticasResumo.add(PraticaResumo(
          nome: p.name,
          categoria: p.category,
          concluida: log?.completed ?? false,
        ));
      }
    }

    // Verifica exame já salvo hoje
    final existente = await exameRepo.getForDate(today);
    if (existente != null) {
      return ExameDiarioState(
        date: today,
        gratidao: existente.gratidao,
        revisaoDia: existente.revisaoDia,
        arrependimento: existente.arrependimento,
        proposito: existente.proposito,
        praticasHoje: praticasResumo,
        isSaved: true,
      );
    }

    return ExameDiarioState(
      date: today,
      praticasHoje: praticasResumo,
    );
  }

  /// Salva o exame do dia.
  Future<void> save(ExameDiarioState fields) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(fields.copyWith(isSaving: true));

    final exame = ExameDiario(
      id: 'exame_diario_${fields.date.millisecondsSinceEpoch}',
      date: fields.date,
      gratidao: fields.gratidao,
      revisaoDia: fields.revisaoDia,
      arrependimento: fields.arrependimento,
      proposito: fields.proposito,
    );

    try {
      await ref.read(exameDiarioRepositoryProvider).save(exame);
      state = AsyncData(fields.copyWith(isSaving: false, isSaved: true));
    } catch (_) {
      state = AsyncData(current.copyWith(isSaving: false));
    }
  }
}

/// Provider do [ExameDiarioController].
final exameDiarioControllerProvider =
    AsyncNotifierProvider<ExameDiarioController, ExameDiarioState>(
  ExameDiarioController.new,
);

/// Retorna a segunda-feira da semana civil à qual [date] pertence.
DateTime startOfWeekFor(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  // weekday: segunda=1 … domingo=7
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Provider: lista de [ExameDiario] da semana corrente (seg–dom).
/// Retorna uma lista de 7 posições (uma por dia); dias sem registro → null.
final exameDiarioSemanaProvider =
    FutureProvider<List<ExameDiario?>>((ref) async {
  final repo = ref.watch(exameDiarioRepositoryProvider);
  final start = startOfWeekFor(DateTime.now());
  final records = await repo.getWeek(start);

  return List.generate(7, (i) {
    final dia = start.add(Duration(days: i));
    final d = DateTime(dia.year, dia.month, dia.day);
    try {
      return records.lastWhere(
        (e) => DateTime(e.date.year, e.date.month, e.date.day) == d,
      );
    } on StateError {
      return null;
    }
  });
});
