import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';

/// Cabeçalho de seção com marcador pilcrow (¶).
///
/// Renderiza "¶ {label}" em Fraunces itálico, cor [AppColors.rubric].
/// Usado em qualquer lista agrupada por categoria (Regra de Vida, Leituras…).
///
/// ```dart
/// SectionPilcrow(label: 'Espiritual'),
/// ```
class SectionPilcrow extends StatelessWidget {
  const SectionPilcrow({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        '¶ $label',
        style: GoogleFonts.fraunces(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: AppColors.rubric,
          height: 1.3,
        ),
      ),
    );
  }
}
