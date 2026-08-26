import 'package:flutter/material.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/domain/entities/book.dart';
import 'package:iter_vitae/domain/entities/reading_session.dart';

/// Formulário de registro de sessão de leitura.
///
/// Retorna `(ReadingSession, int newCurrentPage)` via [Navigator.pop]
/// ou null se cancelado.
///
/// O campo "página atual" é obrigatório. Highlight e application são opcionais.
class ReadingSessionForm extends StatefulWidget {
  const ReadingSessionForm({super.key, required this.book});

  final Book book;

  @override
  State<ReadingSessionForm> createState() => _ReadingSessionFormState();
}

class _ReadingSessionFormState extends State<ReadingSessionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPageCtrl;
  final _minutesCtrl = TextEditingController();
  final _highlightCtrl = TextEditingController();
  final _applicationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pré-preenche com currentPage + 1 como sugestão editável
    final suggestion = widget.book.currentPage > 0
        ? widget.book.currentPage + 1
        : 1;
    _currentPageCtrl = TextEditingController(text: '$suggestion');
  }

  @override
  void dispose() {
    _currentPageCtrl.dispose();
    _minutesCtrl.dispose();
    _highlightCtrl.dispose();
    _applicationCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newPage = int.parse(_currentPageCtrl.text.trim());
    final prevPage = widget.book.currentPage;
    final startPage = prevPage > 0 ? prevPage : null;
    final pagesRead = newPage > prevPage ? newPage - prevPage : null;
    final minutes = int.tryParse(_minutesCtrl.text.trim());

    final session = ReadingSession(
      id: 'rs_${DateTime.now().millisecondsSinceEpoch}',
      bookId: widget.book.id,
      date: DateTime.now(),
      startPage: startPage,
      pagesRead: pagesRead,
      minutesRead: minutes,
      highlight: _highlightCtrl.text.trim().isEmpty
          ? null
          : _highlightCtrl.text.trim(),
      application: _applicationCtrl.text.trim().isEmpty
          ? null
          : _applicationCtrl.text.trim(),
    );

    Navigator.of(context).pop((session, newPage));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registrar leitura',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: false,
        actions: [
          TextButton(onPressed: _submit, child: const Text('Salvar')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Contexto do livro
            Text(
              widget.book.title,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // Página atual (obrigatório)
            _SectionLabel(label: 'Página atual'),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _currentPageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '${widget.book.currentPage}',
                      suffixText: widget.book.totalPages > 0
                          ? '/ ${widget.book.totalPages}'
                          : null,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Obrigatório';
                      }
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 0) return 'Inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tempo de leitura
            _SectionLabel(label: 'Tempo de leitura'),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: _minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  suffixText: 'min',
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Highlight
            _SectionLabel(label: 'O que me chamou atenção'),
            const SizedBox(height: 8),
            TextField(
              controller: _highlightCtrl,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            // Application
            _SectionLabel(label: 'O que posso aplicar'),
            const SizedBox(height: 8),
            TextField(
              controller: _applicationCtrl,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(),
            ),
          ],
        ),
      ),
    );
  }
}

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
