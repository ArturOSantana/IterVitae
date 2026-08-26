/// Virtude a ser exercida — foco ativo de formação, sem prazo fixo.
///
/// Trocar de virtude é uma ação explícita do usuário (nunca automática
/// por calendário): fecha-se [endDate] da atual e abre-se uma nova.
///
/// Sem barra de progresso percentual — fidelidade (%) aplica-se
/// a práticas planejadas, nunca a virtudes.
class Virtue {
  const Virtue({
    required this.id,
    required this.name,
    required this.startDate,
    required this.purpose,
    this.endDate,
    this.reflections = const [],
  });

  final String id;
  final String name;

  /// Data em que esta virtude foi colocada em foco.
  final DateTime startDate;

  /// Data em que o foco foi encerrado; [null] = ainda em foco.
  final DateTime? endDate;

  /// Propósito concreto definido pelo usuário.
  final String purpose;

  /// Reflexões livres registradas ao longo do foco.
  final List<String> reflections;

  /// Verdadeiro enquanto a virtude estiver em foco (sem data de encerramento).
  bool get isActive => endDate == null;

  Virtue copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? purpose,
    List<String>? reflections,
  }) {
    return Virtue(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      purpose: purpose ?? this.purpose,
      reflections: reflections ?? this.reflections,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Virtue && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
