import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/practice.dart';
import '../../../domain/entities/spiritual_direction.dart';
import '../../../providers.dart';
import 'direction_state.dart';

/// Controller da tela Preparação para Direção.
///
/// Agrega dados reais dos repositórios nos três blocos do roteiro do padre.
/// Período: desde a última direção passada até hoje.
/// Fallback quando não há direção anterior: hoje − 45 dias (mock de user.createdAt).
class DirectionController extends AsyncNotifier<DirectionState> {
  @override
  Future<DirectionState> build() async {
    final directionRepo = ref.watch(directionRepositoryProvider);
    final practiceRepo = ref.watch(practiceRepositoryProvider);
    final struggleRepo = ref.watch(struggleRepositoryProvider);
    final reflectionRepo = ref.watch(reflectionRepositoryProvider);
    final bookRepo = ref.watch(bookRepositoryProvider);
    final sessionRepo = ref.watch(readingSessionRepositoryProvider);

    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);

    // ── Resolver período ───────────────────────────────────────────────
    final lastPast = await directionRepo.getLastPast();
    final periodFrom = lastPast != null
        ? DateTime(
            lastPast.date.year,
            lastPast.date.month,
            lastPast.date.day,
          )
        : today0.subtract(const Duration(days: 45)); // fallback: user.createdAt

    // Direção ativa: próxima futura (ou nova criada automaticamente)
    final activeDirection = await directionRepo.getOrCreateNext();

    // periodTo é a data da próxima sessão marcada (ou hoje, o que vier primeiro).
    // Isso garante que o relatório e os blocos cobrem exatamente o intervalo
    // entre a última sessão realizada e a sessão que está por vir.
    final nextDate = DateTime(
      activeDirection.date.year,
      activeDirection.date.month,
      activeDirection.date.day,
    );
    final periodTo = nextDate.isBefore(today0) ? today0 : nextDate;

    // ── Bloco a) Formação espiritual ───────────────────────────────────
    final spiritualPractices =
        await practiceRepo.getPracticesByCategory(PracticeCategory.spiritual);

    final logsA = await practiceRepo.getLogsForPeriod(periodFrom, periodTo);
    final spiritualIds = spiritualPractices.map((p) => p.id).toSet();
    final spiritualLogs =
        logsA.where((l) => spiritualIds.contains(l.practiceId)).toList();

    // Dias no período
    final periodDays = periodTo.difference(periodFrom).inDays + 1;
    final totalPlannedA = spiritualPractices.length * periodDays;
    final totalCompletedA =
        spiritualLogs.where((l) => l.completed).length;

    // Luzes de práticas contemplativas
    final contemplativeIds = spiritualPractices
        .where((p) => p.type == PracticeType.contemplativa)
        .map((p) => p.id)
        .toSet();
    final lights = spiritualLogs
        .where((l) => contemplativeIds.contains(l.practiceId) && l.lights != null)
        .map((l) => l.lights!)
        .take(5) // últimas 5
        .toList();

    final activeStruggle = await struggleRepo.getActive();

    final blockA = BlockAData(
      spiritualPractices: spiritualPractices,
      logs: spiritualLogs,
      totalPlanned: totalPlannedA,
      totalCompleted: totalCompletedA,
      activeStruggle: activeStruggle,
      contemplateLights: lights,
    );

    // ── Bloco b) Formação profissional, social e cultural ──────────────
    final professionalPractices = await practiceRepo
        .getPracticesByCategory(PracticeCategory.professional);
    final culturalPractices =
        await practiceRepo.getPracticesByCategory(PracticeCategory.cultural);
    final bPractices = [...professionalPractices, ...culturalPractices];

    final bIds = bPractices.map((p) => p.id).toSet();
    final bLogs =
        logsA.where((l) => bIds.contains(l.practiceId)).toList();
    final totalPlannedB = bPractices.length * periodDays;
    final totalCompletedB = bLogs.where((l) => l.completed).length;

    // Leituras culturais/profissionais no período (ST-09f)
    final readingSessions =
        await sessionRepo.getForPeriod(periodFrom, periodTo);
    final allBooks = await bookRepo.getAll();
    final readingBooks = allBooks
        .where((b) =>
            b.status == BookStatus.reading &&
            (b.category == ReadingCategory.cultural ||
                b.category == ReadingCategory.professional))
        .toList();

    final blockB = BlockBData(
      practices: bPractices,
      logs: bLogs,
      totalPlanned: totalPlannedB,
      totalCompleted: totalCompletedB,
      recentReadingSessions: readingSessions,
      readingBooks: readingBooks,
    );

    // ── Bloco c) Formação humana ───────────────────────────────────────
    final reflections =
        await reflectionRepo.getForPeriod(periodFrom, periodTo);
    final blockC = BlockCData(recentReflections: reflections);

    return DirectionState(
      activeDirection: activeDirection,
      periodFrom: periodFrom,
      periodTo: periodTo,
      blockA: blockA,
      blockB: blockB,
      blockC: blockC,
    );
  }

  // ── Notas de preparação ────────────────────────────────────────────────

  /// Salva nota em um dos blocos (a, b ou c) na direção ativa.
  Future<void> saveNote(String block, String text) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final notes = current.notes;
    final updatedNotes = switch (block) {
      'a' => notes.copyWith(a: text),
      'b' => notes.copyWith(b: text),
      'c' => notes.copyWith(c: text),
      _ => notes,
    };

    final updatedDirection =
        current.activeDirection.copyWith(notasPreparacao: updatedNotes);
    state = AsyncData(current.copyWith(activeDirection: updatedDirection));

    try {
      await ref.read(directionRepositoryProvider).save(updatedDirection);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  // ── Questões ───────────────────────────────────────────────────────────

  /// Adiciona uma questão para levar ao diretor.
  Future<void> addQuestion(String text) async {
    if (text.trim().isEmpty) return;
    final current = state.valueOrNull;
    if (current == null) return;

    final question = DirectionQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
    );
    final updatedQuestions = [...current.questions, question];
    final updatedDirection =
        current.activeDirection.copyWith(questions: updatedQuestions);
    state = AsyncData(current.copyWith(activeDirection: updatedDirection));

    try {
      await ref.read(directionRepositoryProvider).save(updatedDirection);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  /// Alterna o estado resolvido de uma questão.
  Future<void> toggleQuestion(String questionId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedQuestions = current.questions.map((q) {
      return q.id == questionId ? q.copyWith(resolved: !q.resolved) : q;
    }).toList();

    final updatedDirection =
        current.activeDirection.copyWith(questions: updatedQuestions);
    state = AsyncData(current.copyWith(activeDirection: updatedDirection));

    try {
      await ref.read(directionRepositoryProvider).save(updatedDirection);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

/// Provider do [DirectionController].
final directionControllerProvider =
    AsyncNotifierProvider<DirectionController, DirectionState>(
  DirectionController.new,
);
