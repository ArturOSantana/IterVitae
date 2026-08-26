import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/features/direction/application/direction_controller.dart';
import 'package:iter_vitae/features/direction/application/direction_state.dart';

/// Bloco c) Formação humana.
///
/// Identidade Rubrica: título "¶ c) formação humana".
/// Linha simples com contagem de registros do diário, sem cards coloridos.
/// Nota salva automaticamente ao perder foco.
class DirectionBlockC extends ConsumerStatefulWidget {
  const DirectionBlockC({super.key, required this.data});

  final BlockCData data;

  @override
  ConsumerState<DirectionBlockC> createState() => _DirectionBlockCState();
}

class _DirectionBlockCState extends ConsumerState<DirectionBlockC> {
  late final TextEditingController _noteController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final currentNote =
        ref.read(directionControllerProvider).valueOrNull?.notes.c ?? '';
    _noteController = TextEditingController(text: currentNote);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      ref
          .read(directionControllerProvider.notifier)
          .saveNote('c', _noteController.text);
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
    final count = data.recentReflections.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de seção
          Text(
            '¶ c) formação humana',
            style: GoogleFonts.fraunces(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.rubric,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Família — registros no diário
          _DirectionItemRow(
            label: 'Família',
            value: count == 0
                ? 'sem registros no período'
                : '$count ${count == 1 ? 'registro no diário' : 'registros no diário'}',
          ),

          const SizedBox(height: 16),

          // Nota livre — sem perguntas estruturadas sobre temas sensíveis
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
