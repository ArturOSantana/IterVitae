import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../application/diary_controller.dart';
import '../../../../domain/entities/diary_entry.dart';

/// Tela de criação / edição de uma entrada do Diário.
///
/// Abre como tela própria (não modal) — formulários de compromisso
/// nunca abrem como bottom sheet.
class DiarioEntryScreen extends ConsumerStatefulWidget {
  const DiarioEntryScreen({super.key, this.existing});

  /// Quando não-nulo, estamos editando uma entrada existente.
  final DiaryEntry? existing;

  @override
  ConsumerState<DiarioEntryScreen> createState() => _DiarioEntryScreenState();
}

class _DiarioEntryScreenState extends ConsumerState<DiarioEntryScreen> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existing?.text ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(diaryControllerProvider.notifier).save(
            text,
            existingId: widget.existing?.id,
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Editar entrada' : 'Nova entrada',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _salvar,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: '',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
