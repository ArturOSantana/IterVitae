import 'package:flutter/material.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/domain/entities/book.dart';

/// Formulário de criação/edição de livro.
///
/// Retorna o [Book] criado/editado via [Navigator.pop] ou null se cancelado.
class BookFormScreen extends StatefulWidget {
  const BookFormScreen({super.key, this.existing});

  final Book? existing;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _totalPagesCtrl;
  // Só na criação — nunca aparece em edição para não reabrir
  // a discussão de "não alterar o passado" que já fechamos.
  late final TextEditingController _currentPageCtrl;
  late ReadingCategory _category;
  late BookStatus _status;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _authorCtrl = TextEditingController(text: b?.author ?? '');
    _totalPagesCtrl = TextEditingController(
      text: (b?.totalPages ?? 0) > 0 ? '${b!.totalPages}' : '',
    );
    _currentPageCtrl = TextEditingController();
    _category = b?.category ?? ReadingCategory.spiritual;
    _status = b?.status ?? BookStatus.wantToRead;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _totalPagesCtrl.dispose();
    _currentPageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final totalPages = int.tryParse(_totalPagesCtrl.text.trim()) ?? 0;
    // Ponto de partida declarado — só válido na criação, sem gerar ReadingSession.
    final startPage = _isEditing
        ? (widget.existing?.currentPage ?? 0)
        : (int.tryParse(_currentPageCtrl.text.trim()) ?? 0);
    final saved = Book(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim().isEmpty ? null : _authorCtrl.text.trim(),
      category: _category,
      status: _status,
      currentPage: startPage,
      totalPages: totalPages,
      notes: widget.existing?.notes,
      startedAt: widget.existing?.startedAt,
      finishedAt: widget.existing?.finishedAt,
    );
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar livro' : 'Novo livro',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: false,
        actions: [
          TextButton(onPressed: _submit, child: const Text('Salvar')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
            if (_isEditing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'As alterações não afetam sessões já registradas.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Título
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),

            // Autor
            TextFormField(
              controller: _authorCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Autor'),
            ),
            const SizedBox(height: 20),

            // Categoria
            _SectionLabel(label: 'Categoria'),
            const SizedBox(height: 8),
            _ChipChoice<ReadingCategory>(
              options: const [
                (ReadingCategory.spiritual, 'Espiritual'),
                (ReadingCategory.cultural, 'Cultural'),
                (ReadingCategory.professional, 'Profissional'),
              ],
              selected: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 20),

            // Status inicial (quero ler / lendo — não mostrar "concluído" no formulário)
            _SectionLabel(label: 'Status'),
            const SizedBox(height: 8),
            _ChipChoice<BookStatus>(
              options: const [
                (BookStatus.wantToRead, 'Quero ler'),
                (BookStatus.reading, 'Lendo'),
              ],
              selected: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 20),

            // Total de páginas
            TextFormField(
              controller: _totalPagesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total de páginas',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (int.tryParse(v.trim()) == null) return 'Número inválido.';
                return null;
              },
            ),

            // Página inicial — apenas na criação, nunca na edição
            if (!_isEditing) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: 'Já estou nessa página'),
              const SizedBox(height: 8),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _currentPageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (int.tryParse(v.trim()) == null) return 'Número inválido.';
                    return null;
                  },
                ),
              ),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }

}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _ChipChoice<T> extends StatelessWidget {
  const _ChipChoice({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = value == selected;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(value),
          selectedColor: AppColors.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? AppColors.onPrimaryContainer
                : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          backgroundColor: AppColors.surfaceVariant,
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
