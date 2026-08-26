import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';

/// Cartão de progresso diário.
///
/// Identidade Rubrica: barra de 2 px, preenchimento em [AppColors.rubric],
/// trilho em --border do tema, percentual em Fraunces 16 px.
/// Quando [isComplete] é verdadeiro, preenchimento muda para progressComplete.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  bool get _isComplete => total > 0 && completed == total;
  double get _ratio => total == 0 ? 0 : completed / total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Barra: rubrica no andamento, verde quando completo
    final fillColor =
        _isComplete ? AppColors.progressComplete : AppColors.rubric;
    final pct = (_ratio * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isComplete ? 'Dia completo' : 'Meu dia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _isComplete
                        ? AppColors.progressComplete
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Percentual em Fraunces 16 px
                Text(
                  '$pct%',
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: fillColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Barra fina de 2 px — trilho usa a cor de borda do tema
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _ratio),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  minHeight: 2,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(fillColor),
                ),
              ),
            ),
            if (_isComplete) ...[
              const SizedBox(height: 10),
              Text(
                'Fidelidade ao plano de hoje. Continue firme.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.progressComplete,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
