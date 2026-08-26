import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../application/diary_controller.dart';
import '../../../../domain/entities/diary_entry.dart';

/// Tela do Diário — escrita livre, sem perguntas estruturadas.
///
/// Texto livre; nunca escala nem campo estruturado.
class DiarioScreen extends ConsumerStatefulWidget {
  const DiarioScreen({super.key});

  @override
  ConsumerState<DiarioScreen> createState() => _DiarioScreenState();
}

class _DiarioScreenState extends ConsumerState<DiarioScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(diaryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário'),
        centerTitle: false,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar o diário.\nTente novamente.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) => state.entries.isEmpty
            ? _EmptyState(onNew: _openEditor)
            : _EntryList(entries: state.entries, onNew: _openEditor),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        tooltip: 'Nova entrada',
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  void _openEditor({DiaryEntry? entry}) {
    context.push('/mais/diario/nova', extra: entry);
  }
}

// ── Lista de entradas ─────────────────────────────────────────────────────────

class _EntryList extends StatelessWidget {
  const _EntryList({required this.entries, required this.onNew});

  final List<DiaryEntry> entries;
  final void Function({DiaryEntry? entry}) onNew;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: entries.length,
      separatorBuilder: (context, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _EntryCard(
        entry: entries[i],
        onTap: () => onNew(entry: entries[i]),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat("d 'de' MMMM, yyyy", 'pt_BR').format(entry.date);
    final preview = entry.text.length > 120
        ? '${entry.text.substring(0, 120)}…'
        : entry.text;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                preview,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});

  final void Function({DiaryEntry? entry}) onNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nenhuma entrada ainda.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
