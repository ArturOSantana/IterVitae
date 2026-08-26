import 'package:flutter/material.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';

/// Campo de reflexão noturna (exame de consciência rápido).
///
/// Desabilitado se a reflexão já foi salva hoje ([isSaved] == true).
/// Botão "Salvar" chama [onSave] com o texto digitado.
class ReflectionInput extends StatefulWidget {
  const ReflectionInput({
    super.key,
    required this.onSave,
    this.initialText,
    this.isSaved = false,
  });

  final void Function(String text) onSave;
  final String? initialText;
  final bool isSaved;

  @override
  State<ReflectionInput> createState() => _ReflectionInputState();
}

class _ReflectionInputState extends State<ReflectionInput> {
  late final TextEditingController _controller;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _controller.addListener(() {
      final dirty = _controller.text != (widget.initialText ?? '');
      if (dirty != _isDirty) setState(() => _isDirty = dirty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = !widget.isSaved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.nights_stay_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Como foi meu dia?',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          enabled: enabled,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: '',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (enabled)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: _isDirty
                  ? () => widget.onSave(_controller.text.trim())
                  : null,
              child: const Text('Salvar reflexão'),
            ),
          ),
        if (widget.isSaved)
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 14,
                color: AppColors.progressComplete,
              ),
              const SizedBox(width: 4),
              Text(
                'Reflexão salva.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.progressComplete,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
