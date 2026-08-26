/// Categoria de uma prática no Plano de Vida.
enum PracticeCategory {
  spiritual,    // espiritual
  human,        // humana
  professional, // profissional
  cultural,     // cultural
  apostolate,   // apostolado
}

/// Tipo de prática — determina quais campos aparecem no registro.
/// - [contemplativa]: exibe campos "dificuldade de hoje" e "luz recebida"
/// - [ativa]: exibe campos de duração e reflexão genérica
/// - [formativa]: exibe campo de anotação/aprendizado
///
/// Nunca usar o nome da prática para inferir o tipo.
enum PracticeType {
  contemplativa,
  ativa,
  formativa,
}

/// Frequência de uma prática no Plano de Vida.
///
/// MVP: apenas [daily] e [specificDays].
/// "Semanal sem dia fixo" e "mensal" ficam para fases posteriores.
enum PracticeFrequency {
  /// Todos os dias.
  daily,

  /// Dias específicos da semana, definidos em [Practice.weekdays].
  specificDays,
}

/// Uma prática do Plano de Vida (ex.: "Oração mental", "Exercício físico").
class Practice {
  const Practice({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.scheduledTime,
    this.frequency = PracticeFrequency.daily,
    this.weekdays = const [],
    this.active = true,
    this.updatedAt,
  });

  final String id;
  final String name;
  final PracticeCategory category;
  final PracticeType type;

  /// Horário programado no formato "HH:mm".
  final String scheduledTime;

  /// Frequência da prática.
  final PracticeFrequency frequency;

  /// Dias da semana ativos quando [frequency] == [PracticeFrequency.specificDays].
  /// Valores: 1 = segunda, 2 = terça, …, 7 = domingo (ISO 8601).
  /// Ignorado quando [frequency] == [PracticeFrequency.daily].
  final List<int> weekdays;

  /// Prática ativa no plano atual.
  /// Desativar entra em vigor a partir do dia seguinte — o dia atual
  /// continua exibindo a prática como pendente até meia-noite.
  final bool active;

  /// Data da última atualização da prática.
  /// Não altera o histórico passado — os logs continuam como estavam.
  final DateTime? updatedAt;

  /// Verdadeiro se a prática está programada para [date].
  bool isScheduledFor(DateTime date) {
    if (!active) return false;
    if (frequency == PracticeFrequency.daily) return true;
    return weekdays.contains(date.weekday);
  }

  Practice copyWith({
    String? id,
    String? name,
    PracticeCategory? category,
    PracticeType? type,
    String? scheduledTime,
    PracticeFrequency? frequency,
    List<int>? weekdays,
    bool? active,
    DateTime? updatedAt,
  }) {
    return Practice(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Practice && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
