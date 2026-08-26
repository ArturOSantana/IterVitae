import '../entities/practice.dart';
import '../entities/practice_log.dart';

/// Interface do repositório de práticas.
/// TODO: implementar com Firestore em FirestorePracticeRepository.
abstract interface class PracticeRepository {
  /// Retorna as práticas ativas do plano atual.
  Future<List<Practice>> getActivePractices();

  /// Retorna todas as práticas (ativas e inativas).
  Future<List<Practice>> getAllPractices();

  /// Retorna as práticas de uma categoria específica.
  Future<List<Practice>> getPracticesByCategory(PracticeCategory category);

  /// Retorna o log de uma prática em uma data (null se não registrado).
  Future<PracticeLog?> getLogForDate(String practiceId, DateTime date);

  /// Retorna todos os logs de um período.
  Future<List<PracticeLog>> getLogsForPeriod(DateTime from, DateTime to);

  /// Salva (insere ou atualiza) um log de prática.
  Future<void> saveLog(PracticeLog log);

  /// Salva (insere ou atualiza) uma prática.
  /// Para edição, preserva o histórico existente — apenas [updatedAt] indica a mudança.
  Future<void> savePractice(Practice practice);

  /// Desativa uma prática.
  /// Entra em vigor a partir do dia seguinte; o dia atual continua mostrando
  /// a prática como pendente até meia-noite.
  Future<void> deactivatePractice(String practiceId);
}
