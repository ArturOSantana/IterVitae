import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/widgets/direction_calendar_picker.dart';
import 'package:iter_vitae/core/widgets/segmented_control.dart';
import 'package:iter_vitae/domain/entities/spiritual_direction.dart';
import 'package:iter_vitae/domain/entities/struggle.dart';
import 'package:iter_vitae/features/direction/application/direction_controller.dart';
import 'package:iter_vitae/features/direction/application/direction_report_pdf.dart';
import 'package:iter_vitae/features/direction/application/direction_state.dart';
import 'package:iter_vitae/features/direction/presentation/direction_history_screen.dart';
import 'package:iter_vitae/features/direction/presentation/quick_note_screen.dart';
import 'package:iter_vitae/providers.dart';

import 'widgets/direction_block_a.dart';
import 'widgets/direction_block_b.dart';
import 'widgets/direction_block_c.dart';

/// Tela raiz da aba Direção Espiritual.
///
/// Contém um [SegmentedControl] no topo ("Preparar" / "Histórico").
/// A visão "Preparar" é o conteúdo original (blocos a/b/c, questões, PDF).
/// A visão "Histórico" exibe as direções já realizadas e o fluxo de registro.
class DirectionScreen extends ConsumerStatefulWidget {
  const DirectionScreen({super.key});

  @override
  ConsumerState<DirectionScreen> createState() => _DirectionScreenState();
}

class _DirectionScreenState extends ConsumerState<DirectionScreen> {
  int _selectedTab = 0; // 0 = Preparar, 1 = Histórico

  /// Datas de direções já realizadas — alimenta os pontinhos do calendário.
  Future<List<DateTime>> _pastDates() async {
    final all = await ref.read(directionRepositoryProvider).getAll();
    final today0 = DateTime.now();
    return all
        .where((d) => d.date.isBefore(today0) || d.foiRealizada)
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(directionControllerProvider);

    final appBar = AppBar(
      centerTitle: false,
      title: async.when(
        loading: () => const _DirectionTitle(
          days: null,
          loading: true,
          onDateTap: null,
          onAnotarAgora: null,
        ),
        error: (_, _) => const _DirectionTitle(
          days: null,
          loading: false,
          onDateTap: null,
          onAnotarAgora: null,
        ),
        data: (state) {
          final days = _selectedTab == 0 ? state.daysUntilDirection : null;
          return _DirectionTitle(
            days: days,
            loading: false,
            onDateTap: _selectedTab == 0 && !state.sessaoAtrasada
                ? () => _editarProximaData(context, state)
                : null,
            onAnotarAgora: _selectedTab == 0 && state.daysUntilDirection == 0
                ? () => openQuickNote(context, state.activeDirection)
                : null,
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SegmentedControl(
            options: const ['Preparar', 'Histórico'],
            selectedIndex: _selectedTab,
            onChanged: (i) => setState(() => _selectedTab = i),
          ),
        ),
      ),
    );

    if (_selectedTab == 1) {
      return Scaffold(
        appBar: appBar,
        body: const DirectionHistoryScreen(),
      );
    }

    // ── Aba "Preparar" ────────────────────────────────────────────────────
    return async.when(
      loading: () => Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: appBar,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar a preparação.\nTente novamente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
      data: (state) => Scaffold(
        appBar: appBar,
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Banner "registrar sessão" — aparece quando a sessão já passou
                if (state.sessaoAtrasada)
                  _RegistrarBanner(
                    onTap: () => context.push('/direcao/registrar'),
                    diasAtrasada: -state.daysUntilDirection,
                  ),

                Divider(height: 1, color: AppColors.divider),

                // Card "Luta atual" — antes dos blocos a/b/c
                _LutaAtualCard(data: state.blockA),

                Divider(height: 1, color: AppColors.divider),

                // Bloco a
                DirectionBlockA(data: state.blockA),
                Divider(height: 1, color: AppColors.divider),

                // Bloco b
                DirectionBlockB(data: state.blockB),
                Divider(height: 1, color: AppColors.divider),

                // Bloco c
                DirectionBlockC(data: state.blockC),
                Divider(height: 1, color: AppColors.divider),

                // Questões para o diretor
                _QuestionsSection(
                  questions: state.questions,
                  onAdd: (text) => ref
                      .read(directionControllerProvider.notifier)
                      .addQuestion(text),
                  onToggle: (id) => ref
                      .read(directionControllerProvider.notifier)
                      .toggleQuestion(id),
                ),

                const SizedBox(height: 16),

                // Botão gerar relatório — outline rubrica, largura total
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _GerarRelatorioButton(state: state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Editar próxima data (tocável no header — só quando sessão ainda não passou) ─

  Future<void> _editarProximaData(
    BuildContext context,
    DirectionState state,
  ) async {
    final past = await _pastDates();
    if (!context.mounted) return;

    final picked = await DirectionCalendarPicker.showAsBottomSheet(
      context,
      initialDate: state.activeDirection.date.isAfter(DateTime.now())
          ? state.activeDirection.date
          : null,
      pastDirectionDates: past,
    );
    if (picked == null) return;
    if (!context.mounted) return;

    final updated = state.activeDirection.copyWith(date: picked);
    await ref.read(directionRepositoryProvider).save(updated);
    ref.invalidate(directionControllerProvider);
  }
}

// ── Title com countdown tocável ───────────────────────────────────────────────

class _DirectionTitle extends StatelessWidget {
  const _DirectionTitle({
    required this.days,
    required this.loading,
    required this.onDateTap,
    required this.onAnotarAgora,
  });

  // null  → aba Histórico (não exibe subtítulo)
  // < 0   → sessão atrasada (banner cuida disso; subtítulo some)
  // 0     → sessão hoje
  // > 0   → sessão futura em N dias
  final int? days;
  final bool loading;
  final VoidCallback? onDateTap;
  final VoidCallback? onAnotarAgora;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!loading && days != null && days! >= 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: _subtitle(context)),
              if (onAnotarAgora != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onAnotarAgora,
                  child: Text(
                    'anotar agora',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.rubric,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
        Text(
          'Direção',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _subtitle(BuildContext context) {
    if (days == 0) {
      return GestureDetector(
        onTap: onDateTap,
        child: Text(
          'direção hoje',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.rubric,
              ),
        ),
      );
    }
    // days > 0
    return GestureDetector(
      onTap: onDateTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'próxima direção em $days ${days == 1 ? 'dia' : 'dias'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          if (onDateTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.edit_calendar_outlined,
              size: 12,
              color: AppColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Banner "registrar sessão" ─────────────────────────────────────────────────

/// Aparece no topo da aba "Preparar" quando a sessão marcada já passou
/// e ainda não foi registrada. Empurra o usuário para o fluxo correto.
class _RegistrarBanner extends StatelessWidget {
  const _RegistrarBanner({required this.onTap, required this.diasAtrasada});

  final VoidCallback onTap;
  final int diasAtrasada;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = diasAtrasada == 1
        ? 'A direção de ontem ainda não foi registrada.'
        : 'A direção há $diasAtrasada dias ainda não foi registrada.';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: AppColors.rubric.withValues(alpha: 0.07),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.rubric,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Toque para registrar o que aconteceu na sessão.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.rubric,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card "Luta atual" ─────────────────────────────────────────────────────────

class _LutaAtualCard extends StatelessWidget {
  const _LutaAtualCard({required this.data});

  final BlockAData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.activeStruggle == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '¶ luta atual',
                style: GoogleFonts.fraunces(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: AppColors.rubric,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/regra-de-vida'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.rubric,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Adicionar uma?'),
            ),
          ],
        ),
      );
    }

    final struggle = data.activeStruggle!;
    final weekCounts = _computeWeekCounts(struggle);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: GestureDetector(
        onTap: () => context.push('/luta-semana'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Borda esquerda 2px rubrica
              Container(
                width: 2,
                color: AppColors.rubric,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¶ luta atual',
                      style: GoogleFonts.fraunces(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: AppColors.rubric,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      struggle.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _WeekCountRow(counts: weekCounts),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Conta o status dos dias da semana corrente (segunda–domingo).
  _WeekCounts _computeWeekCounts(Struggle struggle) {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=seg … 7=dom
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    int achieved = 0;
    int fought = 0;
    int noRecord = 0;

    for (var i = 0; i <= endOfWeek.difference(startOfWeek).inDays; i++) {
      final day = startOfWeek.add(Duration(days: i));
      if (day.isAfter(now)) break;
      final log = struggle.dailyLogs.where((l) {
        final ld = DateTime(l.date.year, l.date.month, l.date.day);
        return ld == day;
      }).firstOrNull;

      if (log == null) {
        noRecord++;
      } else if (log.status == DailyStruggleStatus.achieved) {
        achieved++;
      } else {
        fought++;
      }
    }

    return _WeekCounts(achieved: achieved, fought: fought, noRecord: noRecord);
  }
}

class _WeekCounts {
  const _WeekCounts({
    required this.achieved,
    required this.fought,
    required this.noRecord,
  });
  final int achieved;
  final int fought;
  final int noRecord;
}

class _WeekCountRow extends StatelessWidget {
  const _WeekCountRow({required this.counts});
  final _WeekCounts counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      children: [
        _CountItem(label: 'consegui', count: counts.achieved, theme: theme),
        _CountItem(label: 'lutei e caí', count: counts.fought, theme: theme),
        _CountItem(
            label: 'sem registro esta semana',
            count: counts.noRecord,
            theme: theme),
      ],
    );
  }
}

class _CountItem extends StatelessWidget {
  const _CountItem({
    required this.label,
    required this.count,
    required this.theme,
  });

  final String label;
  final int count;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Botão "Gerar relatório para o padre" ──────────────────────────────────────

class _GerarRelatorioButton extends ConsumerWidget {
  const _GerarRelatorioButton({required this.state});

  final DirectionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showSelectionSheet(context, ref),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.rubric,
          side: const BorderSide(color: AppColors.rubric, width: 0.5),
        ),
        child: const Text('gerar relatório para o padre'),
      ),
    );
  }

  void _showSelectionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ReportSelectionSheet(state: state, ref: ref),
    );
  }
}

// ── Seleção de conteúdo + geração real do PDF ─────────────────────────────────

class _ReportSelectionSheet extends StatefulWidget {
  const _ReportSelectionSheet({required this.state, required this.ref});
  final DirectionState state;
  final WidgetRef ref;

  @override
  State<_ReportSelectionSheet> createState() => _ReportSelectionSheetState();
}

class _ReportSelectionSheetState extends State<_ReportSelectionSheet> {
  bool _practices = true;
  bool _statistics = true;
  bool _virtues = true;
  bool _readings = true;
  bool _questions = true;
  bool _diary = false; // desmarcado por padrão — dado sensível

  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O que incluir no relatório?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _CheckItem(
              label: 'Práticas espirituais',
              value: _practices,
              onChanged: (v) => setState(() => _practices = v!),
            ),
            _CheckItem(
              label: 'Estatísticas de fidelidade',
              value: _statistics,
              onChanged: (v) => setState(() => _statistics = v!),
            ),
            _CheckItem(
              label: 'Virtudes',
              value: _virtues,
              onChanged: (v) => setState(() => _virtues = v!),
            ),
            _CheckItem(
              label: 'Leituras',
              value: _readings,
              onChanged: (v) => setState(() => _readings = v!),
            ),
            _CheckItem(
              label: 'Perguntas para o padre',
              value: _questions,
              onChanged: (v) => setState(() => _questions = v!),
            ),
            const Divider(height: 24),
            // Diário — destacado separadamente por ser dado sensível
            Row(
              children: [
                Checkbox(
                  value: _diary,
                  onChanged: (v) => setState(() => _diary = v!),
                  activeColor: AppColors.rubric,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diário pessoal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Dado sensível — desmarcado por padrão.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _generating ? null : _gerar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.rubric,
                ),
                child: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Gerar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _gerar() async {
    setState(() => _generating = true);
    Navigator.pop(context);

    try {
      // Busca virtude ativa para incluir no relatório (opcional)
      final virtue = await widget.ref
          .read(virtueRepositoryProvider)
          .getActiveVirtue();

      final options = ReportOptions(
        incluirPraticas: _practices,
        incluirEstatisticas: _statistics,
        incluirVirtudes: _virtues,
        incluirLeituras: _readings,
        incluirQuestoes: _questions,
        incluirDiario: _diary,
      );

      final bytes = await DirectionReportPdf.generate(
        widget.state,
        options: options,
        activeVirtue: virtue,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'relatorio_direcao.pdf',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível gerar o relatório. Tente novamente.'),
          ),
        );
      }
    }
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

// ── Seção de Questões para o diretor ─────────────────────────────────────────

class _QuestionsSection extends StatefulWidget {
  const _QuestionsSection({
    required this.questions,
    required this.onAdd,
    required this.onToggle,
  });

  final List<DirectionQuestion> questions;
  final void Function(String) onAdd;
  final void Function(String) onToggle;

  @override
  State<_QuestionsSection> createState() => _QuestionsSectionState();
}

class _QuestionsSectionState extends State<_QuestionsSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          Text(
            '¶ questões para o padre',
            style: GoogleFonts.fraunces(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.rubric,
            ),
          ),
          const SizedBox(height: 12),

          // Campo de entrada
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _submit,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),

          // Lista de questões
          if (widget.questions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...widget.questions.map(
              (q) => _QuestionItem(
                question: q,
                onToggle: () => widget.onToggle(q.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }
}

class _QuestionItem extends StatelessWidget {
  const _QuestionItem({required this.question, required this.onToggle});

  final DirectionQuestion question;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                question.resolved
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                size: 18,
                color: question.resolved
                    ? AppColors.success
                    : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              question.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: question.resolved
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
                decoration:
                    question.resolved ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
