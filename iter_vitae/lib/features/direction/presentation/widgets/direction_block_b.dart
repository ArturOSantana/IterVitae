import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/features/direction/application/direction_controller.dart';
import 'package:iter_vitae/features/direction/application/direction_state.dart';

/// Bloco b) Formação profissional, social e cultural.
///
/// Identidade Rubrica: título "¶ b) formação profissional, social e cultural".
/// Linhas simples rótulo/valor com Divider fino entre cada linha.
/// Sem ícones coloridos, sem emoji.
/// Nota salva automaticamente ao perder foco.
class DirectionBlockB extends ConsumerStatefulWidget {
  const DirectionBlockB({super.key, required this.data});

  final BlockBData data;

  @override
  ConsumerState<DirectionBlockB> createState() => _DirectionBlockBState();
}

class _DirectionBlockBState extends ConsumerState<DirectionBlockB> {
  late final TextEditingController _noteController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final currentNote =
        ref.read(directionControllerProvider).valueOrNull?.notes.b ?? '';
    _noteController = TextEditingController(text: currentNote);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      ref
          .read(directionControllerProvider.notifier)
          .saveNote('b', _noteController.text);
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
    final pct = data.totalPlanned == 0
        ? null
        : (data.fidelityRatio * 100).round();

    // Resumo de leitura cultural
    final readingValue = _buildReadingValue(data);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de seção
          Text(
            '¶ b) formação profissional, social e cultural',
            style: GoogleFonts.fraunces(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.rubric,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Trabalho — fidelidade às práticas profissionais
          _DirectionItemRow(
            label: 'Trabalho',
            value: pct != null
                ? 'fidelidade $pct%'
                : 'sem registros no período',
          ),
          Divider(height: 1, thickness: 0.5, color: AppColors.divider),

          // Leitura cultural — livros em andamento
          _DirectionItemRow(
            label: 'Leitura cultural',
            value: readingValue,
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

  /// Monta o valor da linha de leitura cultural (sem emoji, sem %  em bolha).
  String _buildReadingValue(BlockBData data) {
    if (data.readingBooks.isEmpty && data.recentReadingSessions.isEmpty) {
      return 'sem registros no período';
    }
    if (data.readingBooks.isNotEmpty) {
      final book = data.readingBooks.first;
      if (book.totalPages > 0) {
        final pct = (book.progressRatio * 100).round();
        return '${book.title.length > 20 ? '${book.title.substring(0, 20)}…' : book.title}, $pct%';
      }
      return book.title.length > 24
          ? '${book.title.substring(0, 24)}…'
          : book.title;
    }
    final count = data.recentReadingSessions.length;
    return '$count ${count == 1 ? 'sessão' : 'sessões'} no período';
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
