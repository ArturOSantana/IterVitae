/// Registro de uma prática em um dia específico.
class PracticeLog {
  const PracticeLog({
    required this.id,
    required this.practiceId,
    required this.date,
    required this.completed,
    this.skipReason,
    this.reflection,
    this.duration,
    this.lights,
  });

  final String id;
  final String practiceId;
  final DateTime date;
  final bool completed;

  /// Motivo para não ter realizado (ex.: "Falta de tempo").
  final String? skipReason;

  /// Reflexão genérica sobre a prática.
  final String? reflection;

  /// Duração em minutos.
  final int? duration;

  /// Luzes ou graças percebidas — genérico no schema, destacado na UI
  /// apenas quando [Practice.type == PracticeType.contemplativa].
  /// Nunca restringir por [Practice.name].
  final String? lights;

  PracticeLog copyWith({
    String? id,
    String? practiceId,
    DateTime? date,
    bool? completed,
    String? skipReason,
    String? reflection,
    int? duration,
    String? lights,
  }) {
    return PracticeLog(
      id: id ?? this.id,
      practiceId: practiceId ?? this.practiceId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      skipReason: skipReason ?? this.skipReason,
      reflection: reflection ?? this.reflection,
      duration: duration ?? this.duration,
      lights: lights ?? this.lights,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PracticeLog && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
