import '../entities/diary_entry.dart';

/// Interface do repositório do Diário.
/// TODO: implementar com Firestore em FirestoreDiaryRepository.
abstract interface class DiaryRepository {
  /// Retorna todas as entradas ordenadas por data (mais recente primeiro).
  Future<List<DiaryEntry>> getAll();

  /// Retorna entradas de um período.
  Future<List<DiaryEntry>> getForPeriod(DateTime from, DateTime to);

  /// Salva (insere ou atualiza) uma entrada.
  Future<void> save(DiaryEntry entry);

  /// Remove uma entrada pelo id.
  Future<void> delete(String id);
}
