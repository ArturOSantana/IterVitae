/// Registro do Exame Diário de Consciência (estrutura dos Exercícios Espirituais).
///
/// Corresponde a uma noite específica. Um registro por dia.
/// O passo 2 (Pedido de luz) é conteúdo estático da UI — não há campo aqui.
class ExameDiario {
  const ExameDiario({
    required this.id,
    required this.date,
    this.gratidao = '',
    this.revisaoDia = '',
    this.arrependimento = '',
    this.proposito = '',
  });

  final String id;

  /// Data do exame (dia a que se refere, não o horário de salvamento).
  final DateTime date;

  /// Passo 1 — "Pelo que agradeço hoje?"
  final String gratidao;

  /// Passo 3 — "Como vivi este dia?" (reflexão livre; fidelidade das práticas
  /// é exibida automaticamente na UI, não é armazenada aqui).
  final String revisaoDia;

  /// Passo 4 — "Onde falhei? Peço perdão por..."
  final String arrependimento;

  /// Passo 5 — "Meu propósito para amanhã"
  final String proposito;

  ExameDiario copyWith({
    String? id,
    DateTime? date,
    String? gratidao,
    String? revisaoDia,
    String? arrependimento,
    String? proposito,
  }) {
    return ExameDiario(
      id: id ?? this.id,
      date: date ?? this.date,
      gratidao: gratidao ?? this.gratidao,
      revisaoDia: revisaoDia ?? this.revisaoDia,
      arrependimento: arrependimento ?? this.arrependimento,
      proposito: proposito ?? this.proposito,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExameDiario && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
