import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/widgets/direction_calendar_picker.dart';
import 'package:iter_vitae/domain/entities/spiritual_direction.dart';
import 'package:iter_vitae/features/direction/application/direction_controller.dart';
import 'package:iter_vitae/features/direction/application/direction_history_controller.dart';
import 'package:iter_vitae/features/struggle/application/struggle_service.dart';
import 'package:iter_vitae/providers.dart';

/// Formulário para registrar uma direção depois que ela aconteceu.
///
/// Fluxo:
/// - Recebe [existing] para edição de um registro já salvo, ou null para
///   registrar a direção ativa (a que a Preparação estava usando).
/// - Ao salvar: preenche os campos da direção ativa (pontosTrabalhados,
///   orientacoesRecebidas, propositosCombinados).
/// - Se [proximaData] for preenchida, atualiza a sessão futura existente
///   (criada por getOrCreateNext) ou cria uma nova se não houver nenhuma.
class RegisterDirectionScreen extends ConsumerStatefulWidget {
  const RegisterDirectionScreen({super.key, this.existing});

  /// Quando não-nulo, estamos editando um registro existente do histórico.
  final SpiritualDirection? existing;

  @override
  ConsumerState<RegisterDirectionScreen> createState() =>
      _RegisterDirectionScreenState();
}

class _RegisterDirectionScreenState
    extends ConsumerState<RegisterDirectionScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _data;
  late final TextEditingController _pontosCtrl;
  late final TextEditingController _orientacoesCtrl;
  late final TextEditingController _proximaDataCtrl;
  late List<String> _propositos;
  final _novoProposiotoCtrl = TextEditingController();

  DateTime? _proximaData;
  bool _saving = false;
  bool _anotacaoExpanded = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _data = e?.date ?? DateTime.now();
    _pontosCtrl =
        TextEditingController(text: e?.pontosTrabalhados ?? '');
    _orientacoesCtrl =
        TextEditingController(text: e?.orientacoesRecebidas ?? '');
    _propositos = List<String>.from(e?.propositosCombinados ?? []);
    _proximaData = e?.nextDate;
    _proximaDataCtrl = TextEditingController(
      text: _proximaData != null
          ? DateFormat('d/MM/yyyy', 'pt_BR').format(_proximaData!)
          : '',
    );
  }

  @override
  void dispose() {
    _pontosCtrl.dispose();
    _orientacoesCtrl.dispose();
    _proximaDataCtrl.dispose();
    _novoProposiotoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickData(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _data = picked);
  }

  Future<void> _pickProximaData(BuildContext context) async {
    final all = await ref.read(directionRepositoryProvider).getAll();
    if (!context.mounted) return;
    final pastDates = all
        .where((d) => d.foiRealizada)
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .toList();
    final picked = await DirectionCalendarPicker.showAsBottomSheet(
      context,
      initialDate:
          _proximaData ?? DateTime.now().add(const Duration(days: 30)),
      pastDirectionDates: pastDates,
    );
    if (picked != null) {
      setState(() {
        _proximaData = picked;
        _proximaDataCtrl.text =
            DateFormat('d/MM/yyyy', 'pt_BR').format(picked);
      });
    }
  }

  void _addProposito() {
    final text = _novoProposiotoCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _propositos.add(text));
    _novoProposiotoCtrl.clear();
  }

  void _removeProposito(int index) {
    setState(() => _propositos.removeAt(index));
  }

  /// Inicia a criação de uma [Struggle] ativa a partir de um propósito combinado.
  ///
  /// Abre um diálogo para o usuário confirmar/editar o título (o texto do
  /// propósito é pré-preenchido mas editável). O [origemDirecaoId] é preenchido
  /// automaticamente com a direção sendo registrada — sem seletor de origem.
  Future<void> _marcarComoLutaAtual(
    BuildContext context, {
    required String textoProposito,
  }) async {
    // Resolve o id da direção atual — pode ser existing (edição) ou a ativa
    final dirState = ref.read(directionControllerProvider).valueOrNull;
    final origemId = widget.existing?.id ?? dirState?.activeDirection.id;

    final titulo = await showDialog<String>(
      context: context,
      builder: (ctx) => _ConfirmarLutaDialog(tituloProposto: textoProposito),
    );
    if (titulo == null || titulo.trim().isEmpty) return;
    if (!context.mounted) return;

    await StruggleService(ref).criarLuta(
      context,
      titulo: titulo,
      origemDirecaoId: origemId,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(directionRepositoryProvider);

      if (_isEditing) {
        // Editar registro existente
        final updated = widget.existing!.copyWith(
          date: _data,
          pontosTrabalhados: _pontosCtrl.text.trim().isEmpty
              ? null
              : _pontosCtrl.text.trim(),
          orientacoesRecebidas: _orientacoesCtrl.text.trim().isEmpty
              ? null
              : _orientacoesCtrl.text.trim(),
          propositosCombinados: List.unmodifiable(_propositos),
          nextDate: _proximaData,
        );
        await repo.save(updated);
      } else {
        // Preencher a direção ativa (a que a Preparação estava usando)
        final dirState = ref.read(directionControllerProvider).valueOrNull;
        if (dirState != null) {
          final activeId = dirState.activeDirection.id;
          final all = await repo.getAll();
          final active = all.firstWhere((d) => d.id == activeId);
          final updated = active.copyWith(
            date: _data,
            pontosTrabalhados: _pontosCtrl.text.trim().isEmpty
                ? null
                : _pontosCtrl.text.trim(),
            orientacoesRecebidas: _orientacoesCtrl.text.trim().isEmpty
                ? null
                : _orientacoesCtrl.text.trim(),
            propositosCombinados: List.unmodifiable(_propositos),
            nextDate: _proximaData,
          );
          await repo.save(updated);

          // Se próxima data foi definida, atualiza a próxima sessão existente
          // (criada por getOrCreateNext) em vez de criar uma duplicata.
          if (_proximaData != null) {
            final today0 = DateTime.now();
            final futura = all
                .where((d) =>
                    d.id != activeId &&
                    !d.date.isBefore(today0) &&
                    !d.foiRealizada)
                .firstOrNull;
            if (futura != null) {
              // Já existe sessão futura — apenas atualiza a data
              await repo.save(futura.copyWith(
                date: _proximaData!,
                directorName: active.directorName ?? futura.directorName,
              ));
            } else {
              // Não existe nenhuma — cria nova
              final nova = SpiritualDirection(
                id: 'dir_${DateTime.now().millisecondsSinceEpoch}',
                date: _proximaData!,
                directorName: active.directorName,
              );
              await repo.save(nova);
            }
          }
        }
      }

      // Invalida controllers para recarregar dados
      ref.invalidate(directionControllerProvider);
      ref.invalidate(directionHistoryControllerProvider);

      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('d/MM/yyyy', 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar direção' : 'Registrar direção',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
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
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Anotação livre feita durante a conversa (se existir)
            if ((widget.existing?.anotacaoLivre ??
                    ref
                        .read(directionControllerProvider)
                        .valueOrNull
                        ?.activeDirection
                        .anotacaoLivre) !=
                null) ...[
              GestureDetector(
                onTap: () =>
                    setState(() => _anotacaoExpanded = !_anotacaoExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _anotacaoExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ver o que você anotou durante a conversa',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_anotacaoExpanded) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    (widget.existing?.anotacaoLivre ??
                        ref
                            .read(directionControllerProvider)
                            .valueOrNull
                            ?.activeDirection
                            .anotacaoLivre)!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Data da direção
            _SectionLabel(label: 'Data da direção'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickData(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surfaceVariant,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fmt.format(_data),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pontos trabalhados
            _SectionLabel(label: 'Pontos trabalhados'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pontosCtrl,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),

            // Orientações recebidas
            _SectionLabel(label: 'Orientações recebidas'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orientacoesCtrl,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),

            // Propósitos combinados
            _SectionLabel(label: 'Propósitos combinados'),
            const SizedBox(height: 8),
            if (_propositos.isNotEmpty) ...[
              ..._propositos.asMap().entries.map((entry) {
                final i = entry.key;
                final text = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(text, style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _marcarComoLutaAtual(
                                  context,
                                  textoProposito: text,
                                ),
                                child: Text(
                                  'marcar como luta atual',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.rubric,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: AppColors.textMuted,
                        tooltip: 'Remover propósito',
                        onPressed: () => _removeProposito(i),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
            ],

            // Campo para adicionar propósito
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _novoProposiotoCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(),
                    onSubmitted: (_) => _addProposito(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: _addProposito,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar propósito',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Próxima direção (opcional)
            _SectionLabel(label: 'Próxima direção (opcional)'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickProximaData(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surfaceVariant,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _proximaData != null
                            ? fmt.format(_proximaData!)
                            : 'Toque para definir a data',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _proximaData != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (_proximaData != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _proximaData = null;
                          _proximaDataCtrl.clear();
                        }),
                        child: Icon(
                          Icons.clear,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (_proximaData == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Se não definida agora, pode ser preenchida depois editando este registro.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Diálogo que permite confirmar e editar o título antes de criar a Struggle.
///
/// O [tituloProposto] (texto do propósito) é pré-preenchido mas editável —
/// o propósito como escrito pode não ser a frase ideal para o card da Luta.
/// Retorna o título confirmado, ou null se o usuário cancelou.
class _ConfirmarLutaDialog extends StatefulWidget {
  const _ConfirmarLutaDialog({required this.tituloProposto});

  final String tituloProposto;

  @override
  State<_ConfirmarLutaDialog> createState() => _ConfirmarLutaDialogState();
}

class _ConfirmarLutaDialogState extends State<_ConfirmarLutaDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.tituloProposto);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Marcar como luta atual',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirme ou ajuste o título da luta:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.rubric,
          ),
          onPressed: _ctrl.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text(
            'Começar esta luta',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
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
