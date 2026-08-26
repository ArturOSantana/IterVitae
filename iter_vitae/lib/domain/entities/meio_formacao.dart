/// Tipos de evento de formação.
enum TipoMeioFormacao {
  retiro,
  recolhimento,
  circulo,
  meditacaoDirigida,
  outro,
}

/// Extensão de conveniência para rótulos legíveis.
extension TipoMeioFormacaoLabel on TipoMeioFormacao {
  String get label => switch (this) {
        TipoMeioFormacao.retiro => 'Retiro espiritual',
        TipoMeioFormacao.recolhimento => 'Recolhimento',
        TipoMeioFormacao.circulo => 'Círculo de estudo',
        TipoMeioFormacao.meditacaoDirigida => 'Meditação dirigida',
        TipoMeioFormacao.outro => 'Outro',
      };

  /// Título sugerido ao criar um novo evento deste tipo.
  String get sugestedTitle => switch (this) {
        TipoMeioFormacao.retiro => 'Retiro anual',
        TipoMeioFormacao.recolhimento => 'Recolhimento mensal',
        TipoMeioFormacao.circulo => 'Círculo de estudo',
        TipoMeioFormacao.meditacaoDirigida => 'Meditação dirigida',
        TipoMeioFormacao.outro => '',
      };
}

/// Evento pontual de formação espiritual.
///
/// Não tem recorrência nem status de conclusão — é um registro de
/// compromisso/realização de formação (retiro, recolhimento, círculo, etc.).
class MeioFormacao {
  const MeioFormacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.data,
    this.nota,
  });

  final String id;
  final TipoMeioFormacao tipo;

  /// Ex.: "Recolhimento mensal", "Retiro anual de agosto" — editável.
  final String titulo;

  final DateTime data;

  /// Nota livre opcional.
  final String? nota;

  bool get isPast => data.isBefore(DateTime.now());

  MeioFormacao copyWith({
    String? id,
    TipoMeioFormacao? tipo,
    String? titulo,
    DateTime? data,
    String? nota,
    bool clearNota = false,
  }) {
    return MeioFormacao(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      data: data ?? this.data,
      nota: clearNota ? null : nota ?? this.nota,
    );
  }
}
