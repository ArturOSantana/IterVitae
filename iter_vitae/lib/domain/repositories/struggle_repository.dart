import '../entities/struggle.dart';

/// Interface do repositório de lutas espirituais.
/// TODO: implementar com Firestore em FirestoreStruggleRepository.
abstract interface class StruggleRepository {
  /// Retorna a luta ativa atual (status == ativa).
  /// Nunca inferir atividade por [startDate] — usar o campo [status].
  Future<Struggle?> getActive();

  /// Retorna todas as lutas.
  Future<List<Struggle>> getAll();

  /// Salva (insere ou atualiza) uma luta.
  Future<void> save(Struggle struggle);

  /// Registra o estado diário de uma luta.
  Future<void> logDaily(String struggleId, DailyStruggleLog log);
}
