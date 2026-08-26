import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/domain/entities/spiritual_direction.dart';
import 'package:iter_vitae/providers.dart';

/// Abre a tela "Anotar agora" de forma responsiva:
/// - **< 600 px**: `Navigator.push` normal (tela cheia).
/// - **≥ 600 px**: `showDialog` centralizado (~480 px × 70% da altura).
Future<void> openQuickNote(BuildContext context, SpiritualDirection direction) {
  final size = MediaQuery.sizeOf(context);

  if (size.width >= 600) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 480,
          height: size.height * 0.70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: QuickNoteScreen(direction: direction),
          ),
        ),
      ),
    );
  }

  return context.push<void>('/direcao/anotar', extra: direction);
}

/// Tela de anotação livre durante a conversa de direção espiritual.
///
/// Recebe a [SpiritualDirection] ativa via GoRouter `extra`.
/// Salva automaticamente com debounce de 500ms a cada alteração.
/// Não possui botão de salvar — o rodapé indica "salvo automaticamente".
class QuickNoteScreen extends ConsumerStatefulWidget {
  const QuickNoteScreen({super.key, required this.direction});

  final SpiritualDirection direction;

  @override
  ConsumerState<QuickNoteScreen> createState() => _QuickNoteScreenState();
}

class _QuickNoteScreenState extends ConsumerState<QuickNoteScreen> {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  bool _saved = true; // começa como "salvo" (sem alterações ainda)

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.direction.anotacaoLivre ?? '');
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_saved) setState(() => _saved = false);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final text = _ctrl.text;
    final updated = widget.direction.copyWith(
      anotacaoLivre: text.trim().isEmpty ? null : text,
    );
    try {
      await ref.read(directionRepositoryProvider).save(updated);
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      // Silencioso — nova tentativa no próximo evento
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dir = widget.direction;

    // Subtítulo: data + nome do diretor (se preenchido)
    final fmt = DateFormat('d/MM/yyyy', 'pt_BR');
    final subtitle = [
      fmt.format(dir.date),
      if (dir.directorName != null && dir.directorName!.isNotEmpty)
        dir.directorName!,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Anotar agora',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              _debounce?.cancel();
              await _save();
              if (context.mounted) context.pop();
            },
            child: Text(
              'concluir',
              style: TextStyle(color: AppColors.rubric),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Subtítulo discreto
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Campo de texto — ocupa o restante da tela
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: null,
                expands: true,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          // Rodapé "salvo automaticamente"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                Icon(
                  _saved
                      ? Icons.check_circle_outline
                      : Icons.sync_outlined,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _saved ? 'salvo' : 'salvando…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
