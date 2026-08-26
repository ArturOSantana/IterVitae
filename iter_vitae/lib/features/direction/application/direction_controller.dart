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
    final directionRepo = ref.read(directionRepositoryProvider);
    final practiceRepo = ref.read(practiceRepositoryProvider);
    final struggleRepo = ref.read(struggleRepositoryProvider);
    final reflectionRepo = ref.read(reflectionRepositoryProvider);
    final bookRepo = ref.read(bookRepositoryProvider);
    final sessionRepo = ref.read(readingSessionRepositoryProvider);

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

    // Direção ativa: próxima futura — usa getNext() (só leitura) para não
    // gerar escrita no Firestore durante o build. Se não existe nenhuma,
    // usa um placeholder local; a criação real acontece via getOrCreateNext()
    // somente quando o usuário interagir (ex.: salvar nota, abrir RegisterDirection).
    final activeDirection = await directionRepo.getNext() ??
        SpiritualDirection(
          id: '',
          date: today0.add(const Duration(days: 30)),
        );

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

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Garante que a direção ativa existe no repositório.
  /// Se o build usou um placeholder (id == ''), cria a direção real agora.
  Future<SpiritualDirection> _resolveActiveDirection(
      DirectionState current) async {
    if (current.activeDirection.id.isNotEmpty) return current.activeDirection;
    final repo = ref.read(directionRepositoryProvider);
    final real = await repo.getOrCreateNext();
    state = AsyncData(current.copyWith(activeDirection: real));
    return real;
  }

  // ── Notas de preparação ────────────────────────────────────────────────

  /// Salva nota em um dos blocos (a, b ou c) na direção ativa.
  Future<void> saveNote(String block, String text) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final base = await _resolveActiveDirection(current);

    final updatedNotes = switch (block) {
      'a' => base.notasPreparacao.copyWith(a: text),
      'b' => base.notasPreparacao.copyWith(b: text),
      'c' => base.notasPreparacao.copyWith(c: text),
      _ => base.notasPreparacao,
    };

    final updatedDirection = base.copyWith(notasPreparacao: updatedNotes);
    final updatedState = (state.valueOrNull ?? current)
        .copyWith(activeDirection: updatedDirection);
    state = AsyncData(updatedState);

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

    final base = await _resolveActiveDirection(current);

    final question = DirectionQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
    );
    final updatedDirection =
        base.copyWith(questions: [...base.questions, question]);
    final updatedState = (state.valueOrNull ?? current)
        .copyWith(activeDirection: updatedDirection);
    state = AsyncData(updatedState);

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

    final base = await _resolveActiveDirection(current);

    final updatedQuestions = base.questions.map((q) {
      return q.id == questionId ? q.copyWith(resolved: !q.resolved) : q;
    }).toList();

    final updatedDirection = base.copyWith(questions: updatedQuestions);
    final updatedState = (state.valueOrNull ?? current)
        .copyWith(activeDirection: updatedDirection);
    state = AsyncData(updatedState);

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
