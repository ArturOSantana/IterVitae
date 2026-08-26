import '../entities/spiritual_direction.dart';

/// Interface do repositório de direções espirituais.
abstract interface class DirectionRepository {
  /// Retorna todas as direções ordenadas por data.
  Future<List<SpiritualDirection>> getAll();

  /// Retorna a última direção com [date] anterior a hoje (direção passada mais recente).
  /// Retorna null se não existir nenhuma direção passada.
  Future<SpiritualDirection?> getLastPast();

  /// Retorna a próxima direção futura (data >= hoje), ou null se não existir.
  /// Não faz nenhuma escrita.
  Future<SpiritualDirection?> getNext();

  /// Retorna a próxima direção futura (data >= hoje).
  /// Cria e persiste uma nova se não existir.
  Future<SpiritualDirection> getOrCreateNext();

  /// Salva (insere ou atualiza) uma direção.
  Future<void> save(SpiritualDirection direction);
}
