import '../entities/meio_formacao.dart';

/// Contrato de acesso aos [MeioFormacao].
abstract interface class MeioFormacaoRepository {
  /// Retorna todos os eventos, do mais recente para o mais antigo.
  Future<List<MeioFormacao>> getAll();

  /// Retorna o próximo evento futuro (data >= hoje), ou null se não houver.
  Future<MeioFormacao?> getProximo();

  /// Persiste um evento (insert ou update por id).
  Future<void> save(MeioFormacao meio);
}
