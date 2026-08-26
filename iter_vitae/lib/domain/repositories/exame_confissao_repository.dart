import '../entities/exame_confissao_item.dart';
import '../entities/exame_confissao_sessao.dart';

/// Interface do repositório do Exame para Confissão.
/// TODO: implementar com Firestore em FirestoreExameConfissaoRepository.
abstract interface class ExameConfissaoRepository {
  /// Retorna o catálogo completo de itens de exame, ordenados por categoria e [ordem].
  Future<List<ExameConfissaoItem>> getCatalogo();

  /// Retorna a sessão ativa mais recente, ou null se não houver.
  Future<ExameConfissaoSessao?> getSessaoAtiva();

  /// Salva (insere ou atualiza) uma sessão de confissão.
  Future<void> saveSessao(ExameConfissaoSessao sessao);
}
