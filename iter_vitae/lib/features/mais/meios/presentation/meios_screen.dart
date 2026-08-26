import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/features/mais/diario/application/diary_controller.dart';
import 'package:iter_vitae/domain/entities/diary_entry.dart';

/// Tela Meios de formação — registro de eventos pontuais de formação.
///
/// Tipos de evento:
///   - Retiro espiritual
///   - Recolhimento
///   - Círculo de estudo
///   - Encontro de formação
///   - Outro
///
/// Usa o [DiaryRepository] como storage, identificando entradas pelo prefixo
/// de tag "#meios". Sem entidade de domínio nova no MVP.
class MeiosScreen extends ConsumerWidget {
  const MeiosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(diaryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meios de formação'),
        centerTitle: false,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar os registros.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) {
          // Filtra entradas que têm a tag '#meios'
          final meios = state.entries
              .where((e) => e.tags.contains('#meios'))
              .toList();

          return meios.isEmpty
              ? _EmptyState(
                  onNovo: () => _abrirEditor(context, ref),
                )
              : _MeiosList(
                  entries: meios,
                  onNovo: () => _abrirEditor(context, ref),
                  onEditar: (e) => _abrirEditor(context, ref, entry: e),
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirEditor(context, ref),
        tooltip: 'Registrar evento',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _abrirEditor(
    BuildContext context,
    WidgetRef ref, {
    DiaryEntry? entry,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MeioEditor(
        existing: entry,
        onSave: (tipo, texto, data) async {
          // Persiste como DiaryEntry com tag '#meios' e tipo como tag adicional
          final id = entry?.id ??
              'meio_${data.millisecondsSinceEpoch}';
          final novaEntry = DiaryEntry(
            id: id,
            date: data,
            text: texto.isEmpty ? tipo : '$tipo\n\n$texto',
            tags: ['#meios', '#${_tipoSlug(tipo)}'],
          );
          await ref
              .read(diaryControllerProvider.notifier)
              .save(novaEntry.text, existingId: id, tags: novaEntry.tags, date: novaEntry.date);
        },
      ),
    );
  }

  String _tipoSlug(String tipo) =>
      tipo.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z_]'), '');
}

// ── Lista ─────────────────────────────────────────────────────────────────────

class _MeiosList extends StatelessWidget {
  const _MeiosList({
    required this.entries,
    required this.onNovo,
    required this.onEditar,
  });

  final List<DiaryEntry> entries;
  final VoidCallback onNovo;
  final void Function(DiaryEntry) onEditar;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: entries.length,
      separatorBuilder: (context, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _MeioCard(
        entry: entries[i],
        onTap: () => onEditar(entries[i]),
      ),
    );
  }
}

class _MeioCard extends StatelessWidget {
  const _MeioCard({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(entry.date);

    // Primeira linha do texto é o título/tipo
    final lines = entry.text.split('\n');
    final titulo = lines.first.trim();
    final corpo = lines.length > 2 ? lines.skip(2).join('\n').trim() : '';
    final preview =
        corpo.length > 100 ? '${corpo.substring(0, 100)}…' : corpo;

    // Cor de acento baseada no tipo
    final tipoTag = entry.tags.firstWhere(
      (t) => t.startsWith('#') && t != '#meios',
      orElse: () => '#meios',
    );
    final acento = _acentoParaTipo(tipoTag);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador de tipo
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: acento,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titulo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _acentoParaTipo(String tag) {
    return switch (tag) {
      '#retiro_espiritual' => AppColors.spiritual,
      '#recolhimento' => AppColors.spiritual,
      '#círculo_de_estudo' || '#circulo_de_estudo' => AppColors.cultural,
      '#encontro_de_formação' || '#encontro_de_formacao' => AppColors.human,
      _ => AppColors.primary,
    };
  }
}

// ── Editor (bottom sheet) ─────────────────────────────────────────────────────

const _kTipos = [
  'Retiro espiritual',
  'Recolhimento',
  'Círculo de estudo',
  'Encontro de formação',
  'Outro',
];

class _MeioEditor extends StatefulWidget {
  const _MeioEditor({this.existing, required this.onSave});

  final DiaryEntry? existing;
  final Future<void> Function(String tipo, String texto, DateTime data) onSave;

  @override
  State<_MeioEditor> createState() => _MeioEditorState();
}

class _MeioEditorState extends State<_MeioEditor> {
  late String _tipo;
  late final TextEditingController _textoCtrl;
  late DateTime _data;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Se é edição, extrai tipo e texto do entry existente
    if (widget.existing != null) {
      final lines = widget.existing!.text.split('\n');
      _tipo = lines.first.trim();
      if (!_kTipos.contains(_tipo)) _tipo = 'Outro';
      final corpo = lines.length > 2 ? lines.skip(2).join('\n').trim() : '';
      _textoCtrl = TextEditingController(text: corpo);
      _data = widget.existing!.date;
    } else {
      _tipo = _kTipos.first;
      _textoCtrl = TextEditingController();
      _data = DateTime.now();
    }
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _data = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    final dateStr = DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(_data);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho
          Row(
            children: [
              Text(
                isEdit ? 'Editar evento' : 'Registrar evento',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Fechar',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tipo
          Text(
            'Tipo',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _tipo,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _kTipos
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _tipo = v);
            },
          ),
          const SizedBox(height: 14),

          // Data
          Text(
            'Data',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(dateStr, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Anotações
          Text(
            'Anotações (opcional)',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _textoCtrl,
            maxLines: 5,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 16),

          // Salvar
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await widget.onSave(_tipo, _textoCtrl.text.trim(), _data);
                    if (!mounted) return;
                    Navigator.pop(context); // ignore: use_build_context_synchronously
                  },
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Salvar alterações' : 'Registrar'),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNovo});

  final VoidCallback onNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento registrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registre retiros, recolhimentos, círculos de estudo e outros meios de formação.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
