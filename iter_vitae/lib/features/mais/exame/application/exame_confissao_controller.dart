import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/exame_confissao_item.dart';
import '../../../../domain/entities/exame_confissao_sessao.dart';
import '../../../../providers.dart';

// ── Estado ────────────────────────────────────────────────────────────────────

class ExameConfissaoState {
  const ExameConfissaoState({
    required this.catalogo,
    required this.sessao,
    this.isSaving = false,
  });

  /// Catálogo completo de itens, ordenado por categoria.
  final List<ExameConfissaoItem> catalogo;

  /// Sessão ativa (pode ser vazia se recém-iniciada).
  final ExameConfissaoSessao sessao;

  final bool isSaving;

  /// IDs dos itens marcados na sessão atual.
  Set<String> get marcados => sessao.itensMarcados.toSet();

  /// Categorias distintas presentes no catálogo, em ordem de aparição.
  List<String> get categorias {
    final seen = <String>{};
    return catalogo.map((i) => i.categoria).where(seen.add).toList();
  }

  /// Itens filtrados por [categoria].
  List<ExameConfissaoItem> itensDaCategoria(String categoria) =>
      catalogo.where((i) => i.categoria == categoria).toList()
        ..sort((a, b) => a.ordem.compareTo(b.ordem));

  ExameConfissaoState copyWith({
    List<ExameConfissaoItem>? catalogo,
    ExameConfissaoSessao? sessao,
    bool? isSaving,
  }) {
    return ExameConfissaoState(
      catalogo: catalogo ?? this.catalogo,
      sessao: sessao ?? this.sessao,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class ExameConfissaoController extends AsyncNotifier<ExameConfissaoState> {
  @override
  Future<ExameConfissaoState> build() async {
    final repo = ref.read(exameConfissaoRepositoryProvider);
    final catalogo = await repo.getCatalogo();
    final sessaoExistente = await repo.getSessaoAtiva();
    final sessao = sessaoExistente ??
        ExameConfissaoSessao(
          id: 'sessao_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
        );
    return ExameConfissaoState(catalogo: catalogo, sessao: sessao);
  }

  /// Alterna a marcação de um item.
  Future<void> toggleItem(String itemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final marcados = Set<String>.from(current.marcados);
    if (marcados.contains(itemId)) {
      marcados.remove(itemId);
    } else {
      marcados.add(itemId);
    }

    final novaSessao = current.sessao.copyWith(
      itensMarcados: marcados.toList(),
    );

    state = AsyncData(current.copyWith(sessao: novaSessao, isSaving: true));

    try {
      await ref.read(exameConfissaoRepositoryProvider).saveSessao(novaSessao);
      state = AsyncData(current.copyWith(sessao: novaSessao, isSaving: false));
    } catch (_) {
      state = AsyncData(current);
    }
  }

  /// Inicia uma nova sessão, limpando todas as marcações.
  Future<void> novaSessao() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final sessao = ExameConfissaoSessao(
      id: 'sessao_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
    );

    state = AsyncData(current.copyWith(sessao: sessao, isSaving: true));

    try {
      await ref.read(exameConfissaoRepositoryProvider).saveSessao(sessao);
      state = AsyncData(current.copyWith(sessao: sessao, isSaving: false));
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

/// Provider do [ExameConfissaoController].
final exameConfissaoControllerProvider =
    AsyncNotifierProvider<ExameConfissaoController, ExameConfissaoState>(
  ExameConfissaoController.new,
);
