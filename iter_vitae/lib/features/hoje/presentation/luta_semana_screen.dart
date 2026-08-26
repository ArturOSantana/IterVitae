import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/domain/entities/struggle.dart';
import 'package:iter_vitae/features/hoje/application/hoje_controller.dart';
import 'package:iter_vitae/features/hoje/application/luta_semana_controller.dart';

/// Tela de acompanhamento semanal da luta espiritual ativa.
///
/// Estrutura:
/// - Painel comparativo: semana atual vs. semana anterior (contagem simples,
///   sem percentual, sem veredito automático do app).
/// - Grade dos 7 dias da semana corrente com ação de marcação para hoje.
///
/// Sem percentual de vitórias — o conceito de luta não se reduz a número.
class LutaSemanaScreen extends ConsumerWidget {
  const LutaSemanaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semanaAsync = ref.watch(lutaSemanaProvider);
    final hojeAsync = ref.watch(hojeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha luta — semana'),
        centerTitle: false,
      ),
      body: semanaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar a luta.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (semana) {
          if (semana == null) return const _SemLutaState();
          final today = hojeAsync.valueOrNull?.date ?? DateTime.now();
          return _SemanaView(
            semana: semana,
            today: today,
            onMark: (status) => ref
                .read(hojeControllerProvider.notifier)
                .markStruggle(semana.struggle.id, status),
          );
        },
      ),
    );
  }
}

// ── Vista principal ───────────────────────────────────────────────────────────

class _SemanaView extends StatelessWidget {
  const _SemanaView({
    required this.semana,
    required this.today,
    required this.onMark,
  });

  final LutaSemanaState semana;
  final DateTime today;
  final void Function(DailyStruggleStatus) onMark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Título da luta
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.spiritual.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.spiritual.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: AppColors.spiritual),
                  const SizedBox(width: 6),
                  Text(
                    'Luta ativa',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.spiritual,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                semana.struggle.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Painel comparativo ─────────────────────────────────────────
        _ComparativoPanel(
          semanaAtual: semana.semanaAtual,
          semanaAnterior: semana.semanaAnterior,
        ),
        const SizedBox(height: 20),

        // ── Dias da semana corrente ────────────────────────────────────
        Text(
          'Esta semana — dia a dia',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        ...List.generate(7, (i) {
          final dia = semana.semanaAtual.inicio.add(Duration(days: i));
          final isToday = _sameDay(dia, today);
          final isFuture = dia.isAfter(today);
          final status = semana.semanaAtual.dias[i];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DiaCard(
              dia: dia,
              isToday: isToday,
              isFuture: isFuture,
              status: status,
              onMark: isToday ? onMark : null,
            ),
          );
        }),

        const SizedBox(height: 8),
        const _Legenda(),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Painel comparativo semana atual vs. anterior ──────────────────────────────

class _ComparativoPanel extends StatelessWidget {
  const _ComparativoPanel({
    required this.semanaAtual,
    required this.semanaAnterior,
  });

  final LutaSemanaResumo semanaAtual;
  final LutaSemanaResumo semanaAnterior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmtSemana = DateFormat("d/MM", 'pt_BR');
    final atualLabel = '${fmtSemana.format(semanaAtual.inicio)} – '
        '${fmtSemana.format(semanaAtual.inicio.add(const Duration(days: 6)))}';
    final anteriorLabel =
        '${fmtSemana.format(semanaAnterior.inicio)} – '
        '${fmtSemana.format(semanaAnterior.inicio.add(const Duration(days: 6)))}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparativo semanal',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Table(
            border: TableBorder(
              verticalInside: BorderSide(color: AppColors.divider),
              horizontalInside: BorderSide(color: AppColors.divider),
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.4),
              2: FlexColumnWidth(1.4),
            },
            children: [
              // Cabeçalho
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                children: [
                  _CelulaHeader(texto: ''),
                  _CelulaHeader(texto: atualLabel),
                  _CelulaHeader(texto: anteriorLabel),
                ],
              ),
              // Consegui
              TableRow(children: [
                _CelulaLabel(
                  icon: Icons.check_circle_outline,
                  color: AppColors.struggleAchieved,
                  texto: 'Consegui',
                ),
                _CelulaValor(
                  valor: semanaAtual.consegui,
                  color: AppColors.struggleAchieved,
                ),
                _CelulaValor(
                  valor: semanaAnterior.consegui,
                  color: AppColors.struggleAchieved,
                  muted: true,
                ),
              ]),
              // Lutei e caí
              TableRow(children: [
                _CelulaLabel(
                  icon: Icons.shield_outlined,
                  color: AppColors.struggleFought,
                  texto: 'Lutei e caí',
                ),
                _CelulaValor(
                  valor: semanaAtual.luteiECai,
                  color: AppColors.struggleFought,
                ),
                _CelulaValor(
                  valor: semanaAnterior.luteiECai,
                  color: AppColors.struggleFought,
                  muted: true,
                ),
              ]),
              // Nem lutei
              TableRow(children: [
                _CelulaLabel(
                  icon: Icons.close,
                  color: AppColors.struggleDidNotFight,
                  texto: 'Não lutei',
                ),
                _CelulaValor(
                  valor: semanaAtual.naoLutei,
                  color: AppColors.struggleDidNotFight,
                ),
                _CelulaValor(
                  valor: semanaAnterior.naoLutei,
                  color: AppColors.struggleDidNotFight,
                  muted: true,
                ),
              ]),
              // Sem registro
              TableRow(children: [
                _CelulaLabel(
                  icon: Icons.help_outline,
                  color: AppColors.textMuted,
                  texto: 'Sem registro',
                ),
                _CelulaValor(
                  valor: semanaAtual.semRegistro,
                  color: AppColors.textMuted,
                ),
                _CelulaValor(
                  valor: semanaAnterior.semRegistro,
                  color: AppColors.textMuted,
                  muted: true,
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Apenas os números — a conclusão é sua.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _CelulaHeader extends StatelessWidget {
  const _CelulaHeader({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CelulaLabel extends StatelessWidget {
  const _CelulaLabel({
    required this.icon,
    required this.color,
    required this.texto,
  });
  final IconData icon;
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelulaValor extends StatelessWidget {
  const _CelulaValor({
    required this.valor,
    required this.color,
    this.muted = false,
  });
  final int valor;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        '$valor',
        style: GoogleFonts.fraunces(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: muted ? AppColors.textMuted : color,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Card de um dia ────────────────────────────────────────────────────────────

class _DiaCard extends StatelessWidget {
  const _DiaCard({
    required this.dia,
    required this.isToday,
    required this.isFuture,
    required this.status,
    required this.onMark,
  });

  final DateTime dia;
  final bool isToday;
  final bool isFuture;
  final DailyStruggleStatus? status;
  final void Function(DailyStruggleStatus)? onMark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diaNome = DateFormat('EEEE', 'pt_BR').format(dia);
    final diaNum = DateFormat('d/MM', 'pt_BR').format(dia);

    final statusColor = _colorForStatus(status);
    final statusLabel = _labelForStatus(status, isFuture);
    final statusIcon = _iconForStatus(status, isFuture);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primaryContainer.withValues(alpha: 0.3)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.divider,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Data
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalize(diaNome),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isToday
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  diaNum,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Status atual
          Expanded(
            child: Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight:
                        status != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Botões de ação (só hoje)
          if (onMark != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniButton(
                  icon: Icons.check_circle_outline,
                  color: AppColors.struggleAchieved,
                  tooltip: 'Consegui',
                  isActive: status == DailyStruggleStatus.achieved,
                  onTap: () => onMark!(DailyStruggleStatus.achieved),
                ),
                const SizedBox(width: 4),
                _MiniButton(
                  icon: Icons.shield_outlined,
                  color: AppColors.struggleFought,
                  tooltip: 'Lutei e caí',
                  isActive: status == DailyStruggleStatus.fought,
                  onTap: () => onMark!(DailyStruggleStatus.fought),
                ),
                const SizedBox(width: 4),
                _MiniButton(
                  icon: Icons.close,
                  color: AppColors.struggleDidNotFight,
                  tooltip: 'Não lutei',
                  isActive: status == DailyStruggleStatus.didNotFight,
                  onTap: () => onMark!(DailyStruggleStatus.didNotFight),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _colorForStatus(DailyStruggleStatus? s) => switch (s) {
        DailyStruggleStatus.achieved => AppColors.struggleAchieved,
        DailyStruggleStatus.fought => AppColors.struggleFought,
        DailyStruggleStatus.didNotFight => AppColors.struggleDidNotFight,
        null => AppColors.textMuted,
      };

  String _labelForStatus(DailyStruggleStatus? s, bool isFuture) =>
      switch (s) {
        DailyStruggleStatus.achieved => 'Consegui',
        DailyStruggleStatus.fought => 'Lutei e caí',
        DailyStruggleStatus.didNotFight => 'Não lutei',
        null => isFuture ? '—' : 'Não registrado',
      };

  IconData _iconForStatus(DailyStruggleStatus? s, bool isFuture) =>
      switch (s) {
        DailyStruggleStatus.achieved => Icons.check_circle_outline,
        DailyStruggleStatus.fought => Icons.shield_outlined,
        DailyStruggleStatus.didNotFight => Icons.close,
        null =>
          isFuture ? Icons.radio_button_unchecked : Icons.help_outline,
      };

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Mini botão de ação ────────────────────────────────────────────────────────

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? color : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child:
              Icon(icon, size: 16, color: isActive ? color : AppColors.textMuted),
        ),
      ),
    );
  }
}

// ── Legenda ───────────────────────────────────────────────────────────────────

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _LegendaItem(
            icon: Icons.check_circle_outline,
            color: AppColors.struggleAchieved,
            label: 'Consegui',
            theme: theme,
          ),
          _LegendaItem(
            icon: Icons.shield_outlined,
            color: AppColors.struggleFought,
            label: 'Lutei e caí',
            theme: theme,
          ),
          _LegendaItem(
            icon: Icons.close,
            color: AppColors.struggleDidNotFight,
            label: 'Não lutei',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  const _LegendaItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final Color color;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Estado sem luta ───────────────────────────────────────────────────────────

class _SemLutaState extends StatelessWidget {
  const _SemLutaState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nenhuma luta ativa.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
