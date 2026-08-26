import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/domain/entities/book.dart';
import 'package:iter_vitae/domain/entities/reading_session.dart';
import 'package:iter_vitae/features/readings/application/book_detail_controller.dart';
import 'book_form_screen.dart';
import 'reading_session_form.dart';

/// Tela de detalhe de um livro.
class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  static final _dateFmt = DateFormat('d/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookDetailControllerProvider(bookId));
    final theme = Theme.of(context);

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Não foi possível carregar o livro.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
      data: (state) {
        final book = state.book;
        final pct = (book.progressRatio * 100).round();

        // Data relativa da última sessão
        final lastSessionDate =
            state.sessions.isNotEmpty ? state.sessions.first.date : null;
        final lastReadLabel =
            lastSessionDate != null ? _relativeDate(lastSessionDate) : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(book.title, style: theme.textTheme.titleLarge),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar livro',
                onPressed: () => _openEdit(context, ref, book),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── Cabeçalho: autor + categoria ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (book.author != null)
                          Text(book.author!, style: theme.textTheme.bodyMedium),
                        Text(
                          _categoryLabel(book.category),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _categoryColor(book.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (book.status == BookStatus.finished)
                          Text(
                            'Concluído${book.finishedAt != null ? ' em ${_dateFmt.format(book.finishedAt!)}' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.progressComplete,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Bloco de progresso ────────────────────────────────────────
              if (book.totalPages > 0 &&
                  book.status != BookStatus.wantToRead) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$pct%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.progressFill,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${book.currentPage} de ${book.totalPages} páginas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: book.progressRatio,
                    minHeight: 10,
                    backgroundColor: AppColors.progressTrack,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.progressFill),
                  ),
                ),
                if (lastReadLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'última leitura: $lastReadLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              // ── Botão principal ───────────────────────────────────────────
              if (book.status != BookStatus.finished)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _openSession(context, ref, book),
                    child: Text(
                      book.status == BookStatus.wantToRead
                          ? 'Começar a ler'
                          : 'continuar leitura',
                      style: TextStyle(color: AppColors.progressFill),
                    ),
                  ),
                ),

              // ── Notas gerais do livro ─────────────────────────────────────
              if (book.notes != null && book.notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionLabel(label: 'Notas'),
                const SizedBox(height: 6),
                Text(book.notes!, style: theme.textTheme.bodyMedium),
              ],

              // ── Histórico de sessões ──────────────────────────────────────
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '¶ ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.spiritual,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    TextSpan(
                      text: 'Sessões de leitura'.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (state.sessions.isEmpty)
                Text(
                  book.status == BookStatus.wantToRead
                      ? 'Você ainda não começou este livro.'
                      : 'Nenhuma sessão registrada ainda.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                for (final session in state.sessions)
                  _SessionTile(session: session),

              // ── Marcar como concluído ─────────────────────────────────────
              if (book.status != BookStatus.finished) ...[
                const SizedBox(height: 16),
                Text(
                  'marcar como concluído pede confirmação',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => _confirmFinish(context, ref),
                    child: const Text('Marcar como concluído'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'hoje';
    if (diff == 1) return 'ontem';
    return DateFormat('d/MM/yyyy', 'pt_BR').format(date);
  }

  Future<void> _openSession(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final result = await Navigator.of(context).push<(ReadingSession, int)>(
      MaterialPageRoute(
        builder: (_) => ReadingSessionForm(book: book),
      ),
    );
    if (result != null) {
      await ref
          .read(bookDetailControllerProvider(bookId).notifier)
          .saveSession(result.$1, result.$2);
    }
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final saved = await Navigator.of(context).push<Book>(
      MaterialPageRoute(builder: (_) => BookFormScreen(existing: book)),
    );
    if (saved != null) {
      await ref
          .read(bookDetailControllerProvider(bookId).notifier)
          .saveSession(
            // Usa saveSession não — precisamos de um método para só atualizar o livro.
            // Por ora chama o bookRepositoryProvider diretamente é mais limpo:
            // TODO: extrair para BookDetailController.updateBook()
            ReadingSession(
              id: '',
              bookId: bookId,
              date: DateTime.now(),
            ),
            saved.currentPage,
          );
      // Recarrega o estado
      ref.invalidate(bookDetailControllerProvider(bookId));
    }
  }

  Future<void> _confirmFinish(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como concluído'),
        content: const Text(
          'Deseja registrar este livro como concluído?\n'
          'Esta ação pode ser desfeita editando o livro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(bookDetailControllerProvider(bookId).notifier)
          .markFinished();
    }
  }

  String _categoryLabel(ReadingCategory cat) => switch (cat) {
        ReadingCategory.spiritual => 'Espiritual',
        ReadingCategory.cultural => 'Cultural',
        ReadingCategory.professional => 'Profissional',
      };

  Color _categoryColor(ReadingCategory cat) => switch (cat) {
        ReadingCategory.spiritual => AppColors.spiritual,
        ReadingCategory.cultural => AppColors.cultural,
        ReadingCategory.professional => AppColors.professional,
      };
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

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final ReadingSession session;

  static final _dateFmtLong = DateFormat("d 'de' MMMM", 'pt_BR');

  String _pageRange() {
    final startPage = session.startPage;
    if (startPage != null && session.pagesRead != null) {
      return 'páginas $startPage–${startPage + session.pagesRead!}';
    }
    if (session.pagesRead != null) {
      return '${session.pagesRead} págs.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageRange = _pageRange();
    final hasHighlight =
        session.highlight != null && session.highlight!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dateFmtLong.format(session.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (pageRange.isNotEmpty)
                Text(
                  pageRange,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (hasHighlight)
            Text(
              session.highlight!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              'sem anotação',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          Divider(height: 16, color: AppColors.divider),
        ],
      ),
    );
  }
}
