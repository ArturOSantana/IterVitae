import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/theme/practice_icons.dart';
import 'package:iter_vitae/domain/entities/practice.dart';
import 'package:iter_vitae/domain/entities/practice_log.dart';

/// Item de prática na lista diária.
///
/// Identidade Rubrica: nome em Fraunces 14 px. Ação "Concluir" é texto-link
/// em [AppColors.rubric]. Prática concluída mostra "feito" em texto secundário
/// neutro — sem cor de destaque em estados já resolvidos.
class PracticeListItem extends StatelessWidget {
  const PracticeListItem({
    super.key,
    required this.practice,
    required this.log,
    required this.onComplete,
  });

  final Practice practice;
  final PracticeLog? log;
  final VoidCallback onComplete;

  bool get _isCompleted => log?.completed == true;

  Color _categoryColor() {
    return switch (practice.category) {
      PracticeCategory.spiritual => AppColors.spiritual,
      PracticeCategory.human => AppColors.human,
      PracticeCategory.professional => AppColors.professional,
      PracticeCategory.cultural => AppColors.cultural,
      PracticeCategory.apostolate => AppColors.apostolate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _categoryColor();

    return InkWell(
      onTap: _isCompleted ? null : onComplete,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Indicador de categoria
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: _isCompleted ? AppColors.progressComplete : catColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Ícone da categoria
            Icon(
              practiceCategoryIcon(practice.category),
              size: 22,
              color: _isCompleted ? AppColors.textMuted : catColor,
            ),
            const SizedBox(width: 12),
            // Nome em Fraunces 14 px + horário
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    practice.name,
                    style: GoogleFonts.fraunces(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration:
                          _isCompleted ? TextDecoration.lineThrough : null,
                      color: _isCompleted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    practice.scheduledTime,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Ação: "Concluir" como texto-link rubrica / "feito" neutro
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isCompleted
                  ? Text(
                      'feito',
                      key: const ValueKey('done'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : GestureDetector(
                      key: const ValueKey('pending'),
                      onTap: onComplete,
                      child: Text(
                        'Concluir',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.rubric,
                          fontWeight: FontWeight.w600,
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
