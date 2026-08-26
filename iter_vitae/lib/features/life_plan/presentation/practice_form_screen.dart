import 'package:flutter/material.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/theme/practice_icons.dart';
import 'package:iter_vitae/domain/entities/practice.dart';

/// Formulário de criação/edição de prática.
///
/// Recebe [existing] para edição; null para nova prática.
/// Retorna a [Practice] salva via [Navigator.pop] ou null se cancelado.
///
/// Aviso de "a partir de hoje" exibido apenas em edição — não em criação.
class PracticeFormScreen extends StatefulWidget {
  const PracticeFormScreen({super.key, this.existing});

  final Practice? existing;

  @override
  State<PracticeFormScreen> createState() => _PracticeFormScreenState();
}

class _PracticeFormScreenState extends State<PracticeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late PracticeCategory _category;
  late PracticeType _type;
  late PracticeFrequency _frequency;
  late Set<int> _weekdays;
  late String _scheduledTime;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _category = p?.category ?? PracticeCategory.spiritual;
    _type = p?.type ?? PracticeType.contemplativa;
    _frequency = p?.frequency ?? PracticeFrequency.daily;
    _weekdays = Set<int>.from(p?.weekdays ?? []);
    _scheduledTime = p?.scheduledTime ?? '07:00';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_frequency == PracticeFrequency.specificDays && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos um dia da semana.'),
        ),
      );
      return;
    }

    final saved = Practice(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      category: _category,
      type: _type,
      scheduledTime: _scheduledTime,
      frequency: _frequency,
      weekdays: _frequency == PracticeFrequency.specificDays
          ? (List<int>.from(_weekdays)..sort())
          : const [],
      active: widget.existing?.active ?? true,
    );

    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar prática' : 'Nova prática',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Salvar'),
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
            // Aviso de edição
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
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'As alterações valem a partir de hoje. '
                        'O histórico anterior não é modificado.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Ícone da categoria + Nome (linha única)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone fixo da categoria selecionada
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.surfaceVariant,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    practiceCategoryIcon(_category),
                    size: 26,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Categoria
            _SectionLabel(label: 'Categoria'),
            const SizedBox(height: 8),
            _SegmentedChoice<PracticeCategory>(
              options: const [
                (PracticeCategory.spiritual, 'Espiritual'),
                (PracticeCategory.human, 'Humana'),
                (PracticeCategory.professional, 'Profissional'),
                (PracticeCategory.cultural, 'Cultural'),
                (PracticeCategory.apostolate, 'Apostolado'),
              ],
              selected: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 20),

            // Tipo
            _SectionLabel(label: 'Tipo'),
            const SizedBox(height: 4),
            Text(
              'Determina quais campos aparecem ao registrar a prática.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _SegmentedChoice<PracticeType>(
              options: const [
                (PracticeType.contemplativa, 'Contemplativa'),
                (PracticeType.ativa, 'Ativa'),
                (PracticeType.formativa, 'Formativa'),
              ],
              selected: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 20),

            // Horário
            _SectionLabel(label: 'Horário'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickTime(context),
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
                      Icons.access_time,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _scheduledTime,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Frequência
            _SectionLabel(label: 'Frequência'),
            const SizedBox(height: 8),
            _SegmentedChoice<PracticeFrequency>(
              options: const [
                (PracticeFrequency.daily, 'Todos os dias'),
                (PracticeFrequency.specificDays, 'Dias específicos'),
              ],
              selected: _frequency,
              onChanged: (v) => setState(() => _frequency = v),
            ),

            // Seletor de dias da semana (apenas quando specificDays)
            if (_frequency == PracticeFrequency.specificDays) ...[
              const SizedBox(height: 12),
              _WeekdayPicker(
                selected: _weekdays,
                onChanged: (d) => setState(() {
                  if (_weekdays.contains(d)) {
                    _weekdays.remove(d);
                  } else {
                    _weekdays.add(d);
                  }
                }),
              ),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final parts = _scheduledTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 7,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        _scheduledTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
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

/// Seletor de opções em chips — alternativa leve a SegmentedButton
/// que aceita qualquer número de opções sem transbordar.
class _SegmentedChoice<T> extends StatelessWidget {
  const _SegmentedChoice({
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
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
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

/// Seletor de dias da semana (chips togglable).
class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({
    required this.selected,
    required this.onChanged,
  });

  final Set<int> selected;
  final void Function(int) onChanged;

  static const _days = [
    (1, 'Seg'),
    (2, 'Ter'),
    (3, 'Qua'),
    (4, 'Qui'),
    (5, 'Sex'),
    (6, 'Sáb'),
    (7, 'Dom'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _days.map((d) {
        final (iso, label) = d;
        final isOn = selected.contains(iso);
        return FilterChip(
          label: Text(label),
          selected: isOn,
          onSelected: (_) => onChanged(iso),
          selectedColor: AppColors.primaryContainer,
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isOn
                ? AppColors.onPrimaryContainer
                : AppColors.textSecondary,
            fontSize: 13,
          ),
          side: BorderSide(
            color: isOn ? AppColors.primary : AppColors.border,
          ),
          backgroundColor: AppColors.surfaceVariant,
        );
      }).toList(),
    );
  }
}
