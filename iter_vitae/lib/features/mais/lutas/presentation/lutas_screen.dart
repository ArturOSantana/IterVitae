import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/struggle.dart';
import '../application/lutas_controller.dart';

/// Tela Lutas Espirituais — luta ativa + histórico + ações de gestão.
///
/// Regras:
/// - Ao criar nova luta, a ativa é encerrada automaticamente.
/// - Editar altera apenas o título, nunca o histórico.
class LutasScreen extends ConsumerWidget {
  const LutasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lutasControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lutas espirituais'),
        centerTitle: false,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar as lutas.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            // ── Luta ativa ─────────────────────────────────────────────
            if (state.active != null) ...[
              _SectionLabel(label: 'Luta ativa'),
              const SizedBox(height: 8),
              _LutaCard(
                struggle: state.active!,
                isActive: true,
                onEdit: () => _abrirFormulario(
                  context,
                  ref,
                  editando: state.active,
                ),
                onEncerrar: () => _confirmarEncerramento(context, ref),
              ),
              const SizedBox(height: 24),
            ],

            // ── Histórico ───────────────────────────────────────────────
            if (state.history.isNotEmpty) ...[
              _SectionLabel(label: 'Histórico'),
              const SizedBox(height: 8),
              for (final s in state.history) ...[
                _LutaCard(struggle: s, isActive: false),
                const SizedBox(height: 8),
              ],
            ],

            // ── Estado vazio ────────────────────────────────────────────
            if (state.struggles.isEmpty)
              _EmptyState(
                onNova: () => _abrirFormulario(context, ref),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context, ref),
        tooltip: 'Nova luta',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    Struggle? editando,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _LutaForm(
        editando: editando,
        onSalvar: (titulo) async {
          if (editando != null) {
            await ref
                .read(lutasControllerProvider.notifier)
                .editarAtiva(titulo);
          } else {
            await ref
                .read(lutasControllerProvider.notifier)
                .novaLuta(titulo);
          }
        },
      ),
    );
  }

  Future<void> _confirmarEncerramento(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar luta'),
        content: const Text(
          'A luta será movida para o histórico. '
          'Você poderá iniciar uma nova luta a qualquer momento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    await ref.read(lutasControllerProvider.notifier).encerrarAtiva();
  }
}

// ── Card de luta ──────────────────────────────────────────────────────────────

class _LutaCard extends StatelessWidget {
  const _LutaCard({
    required this.struggle,
    required this.isActive,
    this.onEdit,
    this.onEncerrar,
  });

  final Struggle struggle;
  final bool isActive;
  final VoidCallback? onEdit;
  final VoidCallback? onEncerrar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = struggle.endDate == null
        ? 'desde ${DateFormat("d MMM yyyy", 'pt_BR').format(struggle.startDate)}'
        : '${DateFormat("d MMM yyyy", 'pt_BR').format(struggle.startDate)}'
            ' → ${DateFormat("d MMM yyyy", 'pt_BR').format(struggle.endDate!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.rubric.withValues(alpha: 0.05)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.rubric.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 14,
                color: isActive ? AppColors.rubric : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isActive ? AppColors.rubric : AppColors.textMuted,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isActive && onEdit != null) ...[
                _AcaoIcone(
                  icon: Icons.edit_outlined,
                  tooltip: 'Editar',
                  onPressed: onEdit!,
                ),
                _AcaoIcone(
                  icon: Icons.check_circle_outline,
                  tooltip: 'Encerrar',
                  onPressed: onEncerrar ?? () {},
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            struggle.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcaoIcone extends StatelessWidget {
  const _AcaoIcone({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: AppColors.textMuted,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }
}

// ── Formulário (bottom sheet) ─────────────────────────────────────────────────

class _LutaForm extends StatefulWidget {
  const _LutaForm({this.editando, required this.onSalvar});

  final Struggle? editando;
  final Future<void> Function(String titulo) onSalvar;

  @override
  State<_LutaForm> createState() => _LutaFormState();
}

class _LutaFormState extends State<_LutaForm> {
  late final TextEditingController _tituloCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.editando?.title ?? '');
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  bool get _valido => _tituloCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.editando != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho
          Row(
            children: [
              Text(
                isEdit ? 'Editar luta' : 'Nova luta espiritual',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Fechar',
              ),
            ],
          ),

          if (!isEdit) ...[
            const SizedBox(height: 4),
            Text(
              'A luta ativa atual será encerrada automaticamente.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Título da luta
          Text(
            'Luta',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _tituloCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          FilledButton(
            onPressed: (_valido && !_saving)
                ? () async {
                    setState(() => _saving = true);
                    await widget.onSalvar(_tituloCtrl.text.trim());
                    if (!mounted) return;
                    Navigator.pop(context); // ignore: use_build_context_synchronously
                  }
                : null,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Salvar alterações' : 'Colocar em foco'),
          ),
        ],
      ),
    );
  }
}

// ── Auxiliares ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNova});

  final VoidCallback onNova;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Text(
          'Nenhuma luta configurada.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
