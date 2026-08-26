import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/domain/entities/meio_formacao.dart';
import 'package:iter_vitae/providers.dart';

/// Formulário "marcar próxima formação" — tela própria (não modal).
///
/// Campos: tipo, título (pré-sugerido, editável), data, nota (opcional).
class MeioFormacaoFormScreen extends ConsumerStatefulWidget {
  const MeioFormacaoFormScreen({super.key, this.existing});

  /// Se fornecido, o formulário entra em modo de edição.
  final MeioFormacao? existing;

  @override
  ConsumerState<MeioFormacaoFormScreen> createState() =>
      _MeioFormacaoFormScreenState();
}

class _MeioFormacaoFormScreenState
    extends ConsumerState<MeioFormacaoFormScreen> {
  late TipoMeioFormacao _tipo;
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _notaCtrl;
  late DateTime _data;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final m = widget.existing!;
      _tipo = m.tipo;
      _tituloCtrl = TextEditingController(text: m.titulo);
      _notaCtrl = TextEditingController(text: m.nota ?? '');
      _data = m.data;
    } else {
      _tipo = TipoMeioFormacao.recolhimento;
      _tituloCtrl = TextEditingController(
        text: TipoMeioFormacao.recolhimento.sugestedTitle,
      );
      _notaCtrl = TextEditingController();
      _data = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  void _onTipoChanged(TipoMeioFormacao tipo) {
    setState(() {
      _tipo = tipo;
      // Só atualiza o título se estiver vazio ou ainda igual à sugestão anterior
      final sugestaoAtual = _tituloCtrl.text.trim();
      final eraDefault = TipoMeioFormacao.values
          .map((t) => t.sugestedTitle)
          .contains(sugestaoAtual);
      if (sugestaoAtual.isEmpty || eraDefault) {
        _tituloCtrl.text = tipo.sugestedTitle;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _data = picked);
  }

  Future<void> _salvar() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) return;

    setState(() => _saving = true);
    try {
      final meio = MeioFormacao(
        id: widget.existing?.id ??
            'meio_${DateTime.now().millisecondsSinceEpoch}',
        tipo: _tipo,
        titulo: titulo,
        data: _data,
        nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
      );
      await ref.read(meioFormacaoRepositoryProvider).save(meio);
      if (mounted) context.pop(); // ignore: use_build_context_synchronously
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(_data);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          _isEdit ? 'Editar formação' : 'Marcar próxima formação',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              // Tipo
              _FieldLabel(label: 'Tipo'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TipoMeioFormacao.values.map((t) {
                  final selected = _tipo == t;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: selected,
                    selectedColor: AppColors.rubric.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: selected ? AppColors.rubric : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color:
                          selected ? AppColors.rubric : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    onSelected: (_) => _onTipoChanged(t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Título
              _FieldLabel(label: 'Título'),
              const SizedBox(height: 8),
              TextField(
                controller: _tituloCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 20),

              // Data
              _FieldLabel(label: 'Data'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(dateStr, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nota
              _FieldLabel(label: 'Nota (opcional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _notaCtrl,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 32),

              // Botão salvar
              OutlinedButton(
                onPressed: _saving ? null : _salvar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rubric,
                  side: const BorderSide(color: AppColors.rubric),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.rubric,
                        ),
                      )
                    : Text(_isEdit ? 'Salvar alterações' : 'Marcar formação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
