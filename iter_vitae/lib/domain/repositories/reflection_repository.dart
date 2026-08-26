import '../entities/reflection.dart';

/// Interface do repositório de reflexões (exame de consciência).
/// TODO: implementar com Firestore em FirestoreReflectionRepository.
abstract interface class ReflectionRepository {
  /// Retorna a reflexão de uma data específica (null se não registrada).
  Future<Reflection?> getForDate(DateTime date);

  /// Retorna reflexões em um período.
  Future<List<Reflection>> getForPeriod(DateTime from, DateTime to);

  /// Salva (insere ou atualiza) uma reflexão.
  Future<void> save(Reflection reflection);
}
