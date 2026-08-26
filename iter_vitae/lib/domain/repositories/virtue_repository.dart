import 'package:iter_vitae/domain/entities/virtue.dart';

/// Interface do repositório de virtudes.
/// TODO: implementar com Firestore em FirestoreVirtueRepository.
abstract interface class VirtueRepository {
  /// Retorna a virtude atualmente em foco (endDate == null), se houver.
  Future<Virtue?> getActiveVirtue();

  /// Retorna todas as virtudes, da mais recente para a mais antiga.
  Future<List<Virtue>> getAll();

  /// Salva (insere ou atualiza) uma virtude.
  Future<void> save(Virtue virtue);
}
