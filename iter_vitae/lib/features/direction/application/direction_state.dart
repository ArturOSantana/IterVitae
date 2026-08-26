import '../../../domain/entities/book.dart';
import '../../../domain/entities/practice.dart';
import '../../../domain/entities/practice_log.dart';
import '../../../domain/entities/reading_session.dart';
import '../../../domain/entities/struggle.dart';
import '../../../domain/entities/reflection.dart';
import '../../../domain/entities/spiritual_direction.dart';

/// Dados agregados do bloco a) Formação espiritual.
class BlockAData {
  const BlockAData({
    required this.spiritualPractices,
    required this.logs,
    required this.totalPlanned,
    required this.totalCompleted,
    required this.activeStruggle,
    required this.contemplateLights,
  });

  /// Práticas espirituais do período.
  final List<Practice> spiritualPractices;

  /// Logs das práticas espirituais no período.
  final List<PracticeLog> logs;

  final int totalPlanned;
  final int totalCompleted;

  /// Percentual de fidelidade espiritual (0.0–1.0).
  double get fidelityRatio =>
      totalPlanned == 0 ? 0 : totalCompleted / totalPlanned;

  /// Luta ativa no período.
  final Struggle? activeStruggle;

  /// Últimas luzes registradas em práticas contemplativas.
  final List<String> contemplateLights;
}

/// Dados agregados do bloco b) Formação profissional, social e cultural.
class BlockBData {
  const BlockBData({
    required this.practices,
    required this.logs,
    required this.totalPlanned,
    required this.totalCompleted,
    this.recentReadingSessions = const [],
    this.readingBooks = const [],
  });

  final List<Practice> practices;
  final List<PracticeLog> logs;
  final int totalPlanned;
  final int totalCompleted;

  /// Sessões de leitura cultural/profissional no período.
  final List<ReadingSession> recentReadingSessions;

  /// Livros em andamento no período (cultural + profissional).
  final List<Book> readingBooks;

  double get fidelityRatio =>
      totalPlanned == 0 ? 0 : totalCompleted / totalPlanned;
}

/// Dados agregados do bloco c) Formação humana.
class BlockCData {
  const BlockCData({required this.recentReflections});

  /// Reflexões do diário no período.
  final List<Reflection> recentReflections;
}

/// Estado da tela de Preparação para Direção.
class DirectionState {
  const DirectionState({
    required this.activeDirection,
    required this.periodFrom,
    required this.periodTo,
    required this.blockA,
    required this.blockB,
    required this.blockC,
  });

  /// Próxima direção espiritual (onde as notas são salvas).
  final SpiritualDirection activeDirection;

  /// Início do período de agregação (data da última direção passada).
  final DateTime periodFrom;

  /// Fim do período (hoje).
  final DateTime periodTo;

  final BlockAData blockA;
  final BlockBData blockB;
  final BlockCData blockC;

  /// Questões para levar ao diretor.
  List<DirectionQuestion> get questions => activeDirection.questions;

  /// Notas de preparação nos blocos a/b/c.
  DirectionNotes get notes => activeDirection.notasPreparacao;

  /// Dias até a próxima direção.
  ///
  /// - Positivo: sessão futura em N dias
  /// - Zero: sessão é hoje
  /// - Negativo: sessão já passou e ainda não foi registrada (atrasada)
  /// - null: activeDirection não tem data real (estado impossível em produção,
  ///         só ocorre no fallback do getOrCreateNext com data genérica)
  int get daysUntilDirection {
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);
    final dir0 = DateTime(
      activeDirection.date.year,
      activeDirection.date.month,
      activeDirection.date.day,
    );
    return dir0.difference(today0).inDays;
  }

  /// Verdadeiro quando a sessão agendada já passou mas não foi registrada.
  bool get sessaoAtrasada => daysUntilDirection < 0;

  DirectionState copyWith({
    SpiritualDirection? activeDirection,
    DateTime? periodFrom,
    DateTime? periodTo,
    BlockAData? blockA,
    BlockBData? blockB,
    BlockCData? blockC,
  }) {
    return DirectionState(
      activeDirection: activeDirection ?? this.activeDirection,
      periodFrom: periodFrom ?? this.periodFrom,
      periodTo: periodTo ?? this.periodTo,
      blockA: blockA ?? this.blockA,
      blockB: blockB ?? this.blockB,
      blockC: blockC ?? this.blockC,
    );
  }
}
