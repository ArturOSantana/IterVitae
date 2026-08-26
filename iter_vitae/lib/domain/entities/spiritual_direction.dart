// Sentinela para distinguir "não passou" de "passou null" em copyWith.
const _sentinel = Object();

/// Notas de preparação para uma direção espiritual, organizadas
/// nos três blocos do roteiro do padre.
class DirectionNotes {
  const DirectionNotes({this.a, this.b, this.c});

  /// Notas do bloco a) Formação espiritual.
  final String? a;

  /// Notas do bloco b) Formação profissional, social e cultural.
  final String? b;

  /// Notas do bloco c) Formação humana.
  final String? c;

  DirectionNotes copyWith({String? a, String? b, String? c}) {
    return DirectionNotes(
      a: a ?? this.a,
      b: b ?? this.b,
      c: c ?? this.c,
    );
  }
}

/// Questão para levar à próxima direção espiritual.
class DirectionQuestion {
  const DirectionQuestion({
    required this.id,
    required this.text,
    this.resolved = false,
  });

  final String id;
  final String text;
  final bool resolved;

  DirectionQuestion copyWith({String? id, String? text, bool? resolved}) {
    return DirectionQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      resolved: resolved ?? this.resolved,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DirectionQuestion && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Uma sessão de direção espiritual — passada ou futura.
class SpiritualDirection {
  const SpiritualDirection({
    required this.id,
    required this.date,
    this.directorName,
    this.diretorContato,
    this.diretorParoquia,
    this.nextDate,
    this.questions = const [],
    this.notasPreparacao = const DirectionNotes(),
    this.pontosTrabalhados,
    this.orientacoesRecebidas,
    this.propositosCombinados = const [],
    this.anotacaoLivre,
  });

  final String id;

  /// Data em que ocorreu (ou ocorrerá) a direção.
  final DateTime date;

  /// Nome do diretor espiritual.
  final String? directorName;

  /// Telefone ou e-mail do diretor (texto livre).
  final String? diretorContato;

  /// Paróquia / comunidade do diretor (opcional).
  final String? diretorParoquia;

  /// Data prevista para a próxima direção.
  final DateTime? nextDate;

  /// Questões para levar ao diretor.
  final List<DirectionQuestion> questions;

  /// Notas de preparação nos blocos a/b/c.
  final DirectionNotes notasPreparacao;

  /// Resumo dos pontos trabalhados na sessão (preenchido ao registrar).
  final String? pontosTrabalhados;

  /// Orientações recebidas do diretor (preenchido ao registrar).
  final String? orientacoesRecebidas;

  /// Propósitos combinados na sessão (preenchido ao registrar).
  final List<String> propositosCombinados;

  /// Rascunho livre anotado durante a conversa — campo de apoio, sem estrutura.
  /// Não aparece em relatórios PDF; serve de referência ao registrar a sessão.
  final String? anotacaoLivre;

  /// Indica se a direção já foi realizada (possui registro de conteúdo).
  bool get foiRealizada =>
      pontosTrabalhados != null || orientacoesRecebidas != null;

  SpiritualDirection copyWith({
    String? id,
    DateTime? date,
    String? directorName,
    Object? diretorContato = _sentinel,
    Object? diretorParoquia = _sentinel,
    Object? nextDate = _sentinel,
    List<DirectionQuestion>? questions,
    DirectionNotes? notasPreparacao,
    Object? pontosTrabalhados = _sentinel,
    Object? orientacoesRecebidas = _sentinel,
    List<String>? propositosCombinados,
    Object? anotacaoLivre = _sentinel,
  }) {
    return SpiritualDirection(
      id: id ?? this.id,
      date: date ?? this.date,
      directorName: directorName ?? this.directorName,
      diretorContato: diretorContato == _sentinel
          ? this.diretorContato
          : diretorContato as String?,
      diretorParoquia: diretorParoquia == _sentinel
          ? this.diretorParoquia
          : diretorParoquia as String?,
      nextDate: nextDate == _sentinel ? this.nextDate : nextDate as DateTime?,
      questions: questions ?? this.questions,
      notasPreparacao: notasPreparacao ?? this.notasPreparacao,
      pontosTrabalhados: pontosTrabalhados == _sentinel
          ? this.pontosTrabalhados
          : pontosTrabalhados as String?,
      orientacoesRecebidas: orientacoesRecebidas == _sentinel
          ? this.orientacoesRecebidas
          : orientacoesRecebidas as String?,
      propositosCombinados: propositosCombinados ?? this.propositosCombinados,
      anotacaoLivre: anotacaoLivre == _sentinel
          ? this.anotacaoLivre
          : anotacaoLivre as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpiritualDirection && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
