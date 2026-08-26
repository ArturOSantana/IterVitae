import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/widgets/section_pilcrow.dart';
import 'package:iter_vitae/domain/entities/struggle.dart';

/// Cartão da luta espiritual ativa.
///
/// Identidade Rubrica: fundo transparente, borda esquerda de 2 px em
/// [AppColors.rubric]. Cabeçalho via [SectionPilcrow]. Os botões de
/// estado mantêm cores semânticas próprias (consegui/lutei/não lutei);
/// a identidade rubrica está no contêiner, não nos botões.
class StruggleCard extends StatelessWidget {
  const StruggleCard({
    super.key,
    required this.struggle,
    required this.todayStatus,
    required this.onMark,
  });

  final Struggle struggle;
  final DailyStruggleStatus? todayStatus;
  final void Function(DailyStruggleStatus) onMark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        // Fundo neutro — sem cor de categoria
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(color: AppColors.rubric, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: SectionPilcrow + link "Ver semana"
            Row(
              children: [
                // SectionPilcrow sem padding externo — integrado ao card
                Expanded(
                  child: _InlinePilcrow(label: 'luta atual'),
                ),
                GestureDetector(
                  onTap: () => context.push('/luta-semana'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver semana',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.rubric,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.rubric,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              struggle.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            // Botões — outline neutro, sem cor de categoria; só o ativo
            // ganha a cor semântica própria do estado
            Row(
              children: [
                _StatusButton(
                  label: 'Consegui',
                  icon: Icons.check_circle_outline,
                  activeColor: AppColors.struggleAchieved,
                  isActive: todayStatus == DailyStruggleStatus.achieved,
                  onTap: () => onMark(DailyStruggleStatus.achieved),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  label: 'Lutei e caí',
                  icon: Icons.shield_outlined,
                  activeColor: AppColors.struggleFought,
                  isActive: todayStatus == DailyStruggleStatus.fought,
                  onTap: () => onMark(DailyStruggleStatus.fought),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  label: 'Não lutei',
                  icon: Icons.close,
                  activeColor: AppColors.struggleDidNotFight,
                  isActive: todayStatus == DailyStruggleStatus.didNotFight,
                  onTap: () => onMark(DailyStruggleStatus.didNotFight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilcrow inline — mesmo estilo do [SectionPilcrow] mas sem padding externo,
/// para uso dentro de cards.
class _InlinePilcrow extends StatelessWidget {
  const _InlinePilcrow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    // Usa o mesmo estilo do SectionPilcrow mas sem o Padding envolvente
    return SectionPilcrow(label: label);
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color activeColor;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.12) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? activeColor : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : AppColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? activeColor : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
