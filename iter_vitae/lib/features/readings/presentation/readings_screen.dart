import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/widgets/section_pilcrow.dart';
import 'package:iter_vitae/domain/entities/book.dart';
import 'package:iter_vitae/features/readings/application/readings_controller.dart';
import 'book_form_screen.dart';

/// Tela principal de Leituras — biblioteca pessoal agrupada por categoria.
class ReadingsScreen extends ConsumerWidget {
  const ReadingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(readingsControllerProvider);

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text(
            'Não foi possível carregar as leituras.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (state) {
        final grouped = state.grouped;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Leituras',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: false,
          ),
          body: grouped.isEmpty
              ? _EmptyState(
                  onAdd: () => _openBookForm(context, ref, null),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 96),
                  children: [
                    for (final entry in grouped.entries) ...[
                      SectionPilcrow(
                        label: _categoryLabels[entry.key] ?? '',
                      ),
                      for (final book in entry.value) ...[
                        _BookRow(
                          book: book,
                          onTap: () => _openDetail(context, book.id),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.divider,
                        ),
                      ],
                    ],
                  ],
                ),
          bottomNavigationBar: _AddButton(
            onTap: () => _openBookForm(context, ref, null),
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, String bookId) {
    context.push('/leituras/detalhe/$bookId');
  }

  Future<void> _openBookForm(
    BuildContext context,
    WidgetRef ref,
    Book? existing,
  ) async {
    final saved = await Navigator.of(context).push<Book>(
      MaterialPageRoute(builder: (_) => BookFormScreen(existing: existing)),
    );
    if (saved != null) {
      await ref.read(readingsControllerProvider.notifier).saveBook(saved);
    }
  }
}

// ── Labels de categoria ───────────────────────────────────────────────────────

const _categoryLabels = {
  ReadingCategory.spiritual: 'Espiritual',
  ReadingCategory.cultural: 'Cultural',
  ReadingCategory.professional: 'Profissional',
};

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (book.progressRatio * 100).round();
    final isWantToRead = book.status == BookStatus.wantToRead;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (book.author != null) ...[
                    const SizedBox(height: 1),
                    Text(book.author!, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 5),
                  // Barra de progresso sempre visível (ritmo visual uniforme)
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: isWantToRead ? 0.0 : book.progressRatio,
                          minHeight: 2,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.rubric,
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        child: Text(
                          isWantToRead ? 'quero ler' : '$pct%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isWantToRead
                                ? FontWeight.w400
                                : FontWeight.w600,
                            fontStyle: isWantToRead
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: isWantToRead
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(Icons.add, size: 18, color: AppColors.rubric),
          label: const Text('Adicionar livro'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.rubric,
            side: BorderSide(color: AppColors.rubric),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nenhum livro na biblioteca.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
