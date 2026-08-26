import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../application/virtudes_controller.dart';
import '../../../../domain/entities/virtue.dart';

/// Tela Virtudes em Foco — virtude em foco + histórico + ações de gestão.
///
/// Regras de design:
/// - Sem barra de progresso percentual — fidelidade (%) não se aplica a virtudes.
/// - Ao criar nova virtude, a ativa é encerrada automaticamente.
/// - Editar altera apenas nome e propósito, nunca o histórico.
class VirtudesScreen extends ConsumerWidget {
  const VirtudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(virtudesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtudes em foco'),
        centerTitle: false,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar as virtudes.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            // ── Virtude em foco ─────────────────────────────────────────
            if (state.current != null) ...[
              _SectionLabel(label: 'Em foco'),
              const SizedBox(height: 8),
              _VirtueCard(
                virtue: state.current!,
                isCurrent: true,
                onEdit: () => _abrirFormulario(
                  context,
                  ref,
                  editando: state.current,
                ),
                onEncerrar: () => _confirmarEncerramento(context, ref),
              ),
              const SizedBox(height: 24),
            ],

            // ── Histórico ───────────────────────────────────────────────
            if (state.history.isNotEmpty) ...[
              _SectionLabel(label: 'Histórico'),
              const SizedBox(height: 8),
              for (final v in state.history) ...[
                _VirtueCard(virtue: v, isCurrent: false),
                const SizedBox(height: 8),
              ],
            ],

            // ── Estado vazio ────────────────────────────────────────────
            if (state.virtues.isEmpty)
              _EmptyState(
                onNova: () => _abrirFormulario(context, ref),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context, ref),
        tooltip: 'Nova virtude em foco',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    Virtue? editando,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _VirtueForm(
        editando: editando,
        onSalvar: (nome, proposito) async {
          if (editando != null) {
            await ref
                .read(virtudesControllerProvider.notifier)
                .editarAtiva(nome, proposito);
          } else {
            await ref
                .read(virtudesControllerProvider.notifier)
                .novaVirtude(nome, proposito);
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
        title: const Text('Encerrar virtude em foco'),
        content: const Text(
          'A virtude será movida para o histórico. '
          'Você poderá colocar uma nova virtude em foco a qualquer momento.',
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
    await ref.read(virtudesControllerProvider.notifier).encerrarAtiva();
  }
}

// ── Card de virtude ───────────────────────────────────────────────────────────

class _VirtueCard extends StatelessWidget {
  const _VirtueCard({
    required this.virtue,
    required this.isCurrent,
    this.onEdit,
    this.onEncerrar,
  });

  final Virtue virtue;
  final bool isCurrent;
  final VoidCallback? onEdit;
  final VoidCallback? onEncerrar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = virtue.endDate == null
        ? 'desde ${DateFormat("MMM 'de' yyyy", 'pt_BR').format(virtue.startDate)}'
        : '${DateFormat("MMM 'de' yyyy", 'pt_BR').format(virtue.startDate)}'
            ' → ${DateFormat("MMM 'de' yyyy", 'pt_BR').format(virtue.endDate!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.spiritual.withValues(alpha: 0.06)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.spiritual.withValues(alpha: 0.25)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha de data + ações (só para virtude ativa)
          Row(
            children: [
              Icon(
                Icons.spa_outlined,
                size: 14,
                color: isCurrent ? AppColors.spiritual : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        isCurrent ? AppColors.spiritual : AppColors.textMuted,
                    fontWeight:
                        isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isCurrent && onEdit != null) ...[
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
            virtue.name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isCurrent ? AppColors.spiritual : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            virtue.purpose,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
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

class _VirtueForm extends StatefulWidget {
  const _VirtueForm({this.editando, required this.onSalvar});

  final Virtue? editando;
  final Future<void> Function(String nome, String proposito) onSalvar;

  @override
  State<_VirtueForm> createState() => _VirtueFormState();
}

class _VirtueFormState extends State<_VirtueForm> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _propositoCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.editando?.name ?? '');
    _propositoCtrl =
        TextEditingController(text: widget.editando?.purpose ?? '');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _propositoCtrl.dispose();
    super.dispose();
  }

  bool get _valido =>
      _nomeCtrl.text.trim().isNotEmpty &&
      _propositoCtrl.text.trim().isNotEmpty;

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
                isEdit ? 'Editar virtude' : 'Nova virtude em foco',
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
              'A virtude ativa atual será encerrada automaticamente.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Nome da virtude
          Text(
            'Virtude',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nomeCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Propósito concreto
          Text(
            'Propósito concreto',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _propositoCtrl,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          FilledButton(
            onPressed: (_valido && !_saving)
                ? () async {
                    setState(() => _saving = true);
                    await widget.onSalvar(
                      _nomeCtrl.text.trim(),
                      _propositoCtrl.text.trim(),
                    );
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
          'Nenhuma virtude configurada.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

