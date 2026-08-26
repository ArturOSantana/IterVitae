import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/widgets/section_pilcrow.dart';
import 'package:iter_vitae/domain/entities/virtue.dart';

/// Banner da virtude trabalhada no mês.
///
/// Identidade Rubrica: cabeçalho via [SectionPilcrow], nome da virtude
/// em Fraunces. Sem fundo colorido — container neutro, sem decoração
/// de categoria.
class VirtueBanner extends StatelessWidget {
  const VirtueBanner({super.key, required this.virtue});

  final Virtue virtue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho de seção com pilcrow
        const SectionPilcrow(label: 'virtude a ser exercida'),
        const SizedBox(height: 4),
        // Conteúdo: fundo neutro, sem cor de categoria
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome da virtude em Fraunces
              Text(
                virtue.name,
                style: GoogleFonts.fraunces(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                virtue.purpose,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
