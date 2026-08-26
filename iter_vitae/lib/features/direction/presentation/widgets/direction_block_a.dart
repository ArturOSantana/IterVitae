import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/features/direction/application/direction_controller.dart';
import 'package:iter_vitae/features/direction/application/direction_state.dart';

/// Bloco a) Formação espiritual da tela de Preparação para Direção.
///
/// Identidade Rubrica: título "¶ a) formação espiritual" em Fraunces itálico.
/// Linhas simples rótulo/valor com Divider fino entre cada linha.
/// Nota salva automaticamente ao perder foco.
class DirectionBlockA extends ConsumerStatefulWidget {
  const DirectionBlockA({super.key, required this.data});

  final BlockAData data;

  @override
  ConsumerState<DirectionBlockA> createState() => _DirectionBlockAState();
}

class _DirectionBlockAState extends ConsumerState<DirectionBlockA> {
  late final TextEditingController _noteController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final currentNote =
        ref.read(directionControllerProvider).valueOrNull?.notes.a ?? '';
    _noteController = TextEditingController(text: currentNote);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      ref
          .read(directionControllerProvider.notifier)
          .saveNote('a', _noteController.text);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final pct = (data.fidelityRatio * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de seção
          Text(
            '¶ a) formação espiritual',
            style: GoogleFonts.fraunces(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.rubric,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Plano de vida — fidelidade
          _DirectionItemRow(
            label: 'Plano de vida',
            value: data.totalPlanned == 0
                ? 'sem registros no período'
                : 'fidelidade $pct%',
          ),
          Divider(height: 1, thickness: 0.5, color: AppColors.divider),

          // Oração mental — dificuldades (luzes contemplativas)
          _DirectionItemRow(
            label: 'Oração mental',
            value: data.contemplateLights.isEmpty
                ? 'sem registros no período'
                : '${data.contemplateLights.length} '
                    '${data.contemplateLights.length == 1 ? 'luz registrada' : 'luzes registradas'}',
          ),
          Divider(height: 1, thickness: 0.5, color: AppColors.divider),

          // Meios de formação — práticas espirituais
          _DirectionItemRow(
            label: 'Meios de formação',
            value: data.spiritualPractices.isEmpty
                ? 'nenhum cadastrado'
                : data.spiritualPractices.first.name,
          ),

          const SizedBox(height: 16),

          // Nota livre — salva ao perder foco
          TextField(
            controller: _noteController,
            focusNode: _focusNode,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(),
          ),
        ],
      ),
    );
  }
}

// ── Widgets compartilhados ────────────────────────────────────────────────────

/// Linha chave-valor: rótulo à esquerda, valor à direita, sem ícones.
class _DirectionItemRow extends StatelessWidget {
  const _DirectionItemRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.fraunces(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
