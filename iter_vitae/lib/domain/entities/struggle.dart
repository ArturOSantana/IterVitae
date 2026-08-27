/// Estado do dia em uma luta espiritual.
enum DailyStruggleStatus {
  achieved,    // consegui
  fought,      // lutei e caí
  didNotFight, // não lutei
}

/// Status geral de uma luta ao longo do tempo.
enum StruggleStatus {
  ativa,
  encerrada,
}

/// Registro de uma luta em um dia específico.
class DailyStruggleLog {
  const DailyStruggleLog({
    required this.date,
    required this.status,
  });

  final DateTime date;
  final DailyStruggleStatus status;

  DailyStruggleLog copyWith({DateTime? date, DailyStruggleStatus? status}) {
    return DailyStruggleLog(
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}

/// Uma luta espiritual combinada em uma direção e acompanhada no dia a dia.
///
/// [origemDirecaoId] aponta para a direção onde a luta foi combinada.
/// [encerradaEmDirecaoId] aponta para a direção onde foi revisada/encerrada —
/// nullable porque uma luta pode atravessar mais de uma direção antes de ser encerrada.

/// Sentinela para distinguir "não passou" de "passou null" em [Struggle.copyWith].
const _sentinel = Object();

class Struggle {
  const Struggle({
    required this.id,
    required this.title,
    required this.status,
    required this.startDate,
    this.origemDirecaoId,
    this.encerradaEmDirecaoId,
    this.endDate,
    this.dailyLogs = const [],
  });

  final String id;
  final String title;
  final StruggleStatus status;

  /// ID da [SpiritualDirection] onde esta luta foi combinada (null quando criada diretamente).
  final String? origemDirecaoId;

  /// ID da [SpiritualDirection] onde esta luta foi encerrada (nullable).
  final String? encerradaEmDirecaoId;

  final DateTime startDate;
  final DateTime? endDate;
  final List<DailyStruggleLog> dailyLogs;

  Struggle copyWith({
    String? id,
    String? title,
    StruggleStatus? status,
    Object? origemDirecaoId = _sentinel,
    Object? encerradaEmDirecaoId = _sentinel,
    DateTime? startDate,
    Object? endDate = _sentinel,
    List<DailyStruggleLog>? dailyLogs,
  }) {
    return Struggle(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      origemDirecaoId: origemDirecaoId == _sentinel
          ? this.origemDirecaoId
          : origemDirecaoId as String?,
      encerradaEmDirecaoId: encerradaEmDirecaoId == _sentinel
          ? this.encerradaEmDirecaoId
          : encerradaEmDirecaoId as String?,
      startDate: startDate ?? this.startDate,
      endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
      dailyLogs: dailyLogs ?? this.dailyLogs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Struggle && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
