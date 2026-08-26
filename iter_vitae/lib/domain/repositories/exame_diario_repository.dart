import '../entities/exame_diario.dart';

/// Interface do repositório do Exame Diário de Consciência.
/// TODO: implementar com Firestore em FirestoreExameDiarioRepository.
abstract interface class ExameDiarioRepository {
  /// Retorna o exame registrado para [date], ou null se ainda não houver.
  Future<ExameDiario?> getForDate(DateTime date);

  /// Retorna os exames registrados na semana que começa em [startOfWeek]
  /// (inclusive) até [startOfWeek] + 6 dias (inclusive).
  Future<List<ExameDiario>> getWeek(DateTime startOfWeek);

  /// Salva (insere ou atualiza) um registro de exame.
  Future<void> save(ExameDiario exame);
}
