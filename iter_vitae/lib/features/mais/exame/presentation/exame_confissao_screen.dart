import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../application/exame_confissao_controller.dart';

/// Tela do Exame para Confissão — checklist de referência por categoria.
///
/// Não é um registro recorrente: o usuário marca os itens na hora de
/// se preparar para confessar e pode iniciar uma nova sessão a qualquer momento.
/// Sem contagem de itens marcados nem qualquer elemento de pontuação.
class ExameConfissaoScreen extends ConsumerWidget {
  const ExameConfissaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(exameConfissaoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exame para confissão'),
        centerTitle: false,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar o exame.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (state) => _ConfissaoLista(
              state: state,
              onToggle: (id) => ref
                  .read(exameConfissaoControllerProvider.notifier)
                  .toggleItem(id),
              onNovaSessao: () => ref
                  .read(exameConfissaoControllerProvider.notifier)
                  .novaSessao(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lista agrupada por categoria ──────────────────────────────────────────────

class _ConfissaoLista extends StatelessWidget {
  const _ConfissaoLista({
    required this.state,
    required this.onToggle,
    required this.onNovaSessao,
  });

  final ExameConfissaoState state;
  final void Function(String itemId) onToggle;
  final VoidCallback onNovaSessao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categorias = state.categorias;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── Botão nova sessão ──────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: state.isSaving ? null : onNovaSessao,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Nova sessão de confissão'),
        ),
        const SizedBox(height: 4),
        Text(
          'Limpa todas as marcações e começa do zero.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),

        // ── Grupos por categoria ───────────────────────────────────────
        for (final categoria in categorias) ...[
          _CategoriaHeader(label: categoria),
          const SizedBox(height: 4),
          ...state.itensDaCategoria(categoria).map(
                (item) => _ItemExame(
                  texto: item.texto,
                  marcado: state.marcados.contains(item.id),
                  onChanged: (_) => onToggle(item.id),
                ),
              ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ── Cabeçalho de categoria ────────────────────────────────────────────────────

class _CategoriaHeader extends StatelessWidget {
  const _CategoriaHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const Divider(height: 8, color: AppColors.divider),
        ],
      ),
    );
  }
}

// ── Item de exame com checkbox ────────────────────────────────────────────────

class _ItemExame extends StatelessWidget {
  const _ItemExame({
    required this.texto,
    required this.marcado,
    required this.onChanged,
  });

  final String texto;
  final bool marcado;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!marcado),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: marcado,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  texto,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: marcado
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    decoration:
                        marcado ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
