import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/theme/practice_icons.dart';
import 'package:iter_vitae/core/widgets/section_pilcrow.dart';
import 'package:iter_vitae/domain/entities/practice.dart';
import 'package:iter_vitae/features/life_plan/application/life_plan_controller.dart';
import 'practice_form_screen.dart';

/// Tela Regra de Vida — lista de práticas agrupadas por categoria.
class LifePlanScreen extends ConsumerWidget {
  const LifePlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lifePlanControllerProvider);

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text(
            'Não foi possível carregar a Regra de Vida.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (state) {
        final grouped = state.grouped;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Regra de Vida',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: false,
          ),
          body: grouped.isEmpty
              ? _EmptyState(onAdd: () => _openForm(context, ref, null))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 96),
                  children: [
                    for (final entry in grouped.entries) ...[
                      SectionPilcrow(
                        label: _categoryLabels[entry.key] ?? '',
                      ),
                      for (final practice in entry.value) ...[
                        _PracticeRow(
                          practice: practice,
                          onTap: () => _openForm(context, ref, practice),
                          onDeactivate: () => _confirmDeactivate(
                            context,
                            ref,
                            practice,
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.divider,
                        ),
                      ],
                    ],
                  ],
                ),
          bottomNavigationBar: _AddButton(
            onTap: () => _openForm(context, ref, null),
          ),
        );
      },
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Practice? practice,
  ) async {
    final saved = await Navigator.of(context).push<Practice>(
      MaterialPageRoute(
        builder: (_) => PracticeFormScreen(existing: practice),
      ),
    );
    if (saved == null) return;
    try {
      await ref.read(lifePlanControllerProvider.notifier).savePractice(saved);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar a prática. Verifique sua conexão e tente novamente.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    Practice practice,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar prática'),
        content: Text(
          '"${practice.name}" será removida do plano a partir de amanhã. '
          'O histórico de hoje e dos dias anteriores não é alterado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Desativar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(lifePlanControllerProvider.notifier)
          .deactivatePractice(practice.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível desativar a prática. Verifique sua conexão e tente novamente.',
          ),
        ),
      );
    }
  }
}

// ── Labels de categoria ───────────────────────────────────────────────────────

const _categoryLabels = {
  PracticeCategory.spiritual: 'Espiritual',
  PracticeCategory.human: 'Humana',
  PracticeCategory.professional: 'Profissional',
  PracticeCategory.cultural: 'Cultural',
  PracticeCategory.apostolate: 'Apostolado',
};

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    required this.practice,
    required this.onTap,
    required this.onDeactivate,
  });

  final Practice practice;
  final VoidCallback onTap;
  final VoidCallback onDeactivate;

  String get _frequencySummary {
    if (practice.frequency == PracticeFrequency.daily) return 'Todos os dias';
    if (practice.weekdays.isEmpty) return 'Dias específicos';
    const names = {
      1: 'Seg',
      2: 'Ter',
      3: 'Qua',
      4: 'Qui',
      5: 'Sex',
      6: 'Sáb',
      7: 'Dom',
    };
    final sorted = List<int>.from(practice.weekdays)..sort();
    return sorted.map((d) => names[d] ?? '').join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              practiceCategoryIcon(practice.category),
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    practice.name,
                    style: GoogleFonts.fraunces(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${practice.scheduledTime} · $_frequencySummary',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: () => _showMenu(context),
              tooltip: 'Opções',
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: AppColors.error),
              title: Text(
                'Desativar',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDeactivate();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(Icons.add, size: 18, color: AppColors.rubric),
          label: const Text('Nova prática'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.rubric,
            side: BorderSide(color: AppColors.rubric),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nenhuma prática configurada.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
