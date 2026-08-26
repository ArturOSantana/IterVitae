import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Calendário de seleção de data para "próxima direção".
///
/// Pode ser exibido como bottom sheet ou diálogo centralizado via
/// [showDirectionCalendarPicker]. Também pode ser embutido diretamente
/// num formulário.
///
/// Recebe [pastDirectionDates] para exibir pontinhos nos dias em que já
/// houve uma direção registrada.
///
/// Retorna a data escolhida via [onDateSelected].
class DirectionCalendarPicker extends StatefulWidget {
  const DirectionCalendarPicker({
    super.key,
    required this.onDateSelected,
    this.initialDate,
    this.pastDirectionDates = const [],
    this.showDragHandle = true,
  });

  final ValueChanged<DateTime> onDateSelected;
  final DateTime? initialDate;

  /// Datas em que já houve direção — gera pontos abaixo do número do dia.
  final List<DateTime> pastDirectionDates;

  /// Exibe a alcinha de arrastar no topo. Deve ser false quando usado como
  /// diálogo centralizado (sem bottom sheet).
  final bool showDragHandle;

  /// Abre o widget via [showDirectionCalendarPicker].
  /// Mantido por retrocompatibilidade.
  static Future<DateTime?> showAsBottomSheet(
    BuildContext context, {
    DateTime? initialDate,
    List<DateTime> pastDirectionDates = const [],
  }) =>
      showDirectionCalendarPicker(
        context,
        initialDate: initialDate,
        pastDirectionDates: pastDirectionDates,
      );

  @override
  State<DirectionCalendarPicker> createState() =>
      _DirectionCalendarPickerState();
}

/// Helper responsivo para abrir o calendário de data da próxima direção.
///
/// - **< 600 px**: `showModalBottomSheet` (comportamento original).
/// - **≥ 600 px**: `showDialog` centralizado, largura fixa 360 px.
///
/// Retorna a data escolhida ou `null` se descartado.
Future<DateTime?> showDirectionCalendarPicker(
  BuildContext context, {
  DateTime? initialDate,
  List<DateTime> pastDirectionDates = const [],
}) async {
  final width = MediaQuery.sizeOf(context).width;
  DateTime? result;

  if (width >= 600) {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 360,
          child: DirectionCalendarPicker(
            initialDate: initialDate,
            pastDirectionDates: pastDirectionDates,
            showDragHandle: false,
            onDateSelected: (d) {
              result = d;
              Navigator.of(dialogCtx).pop();
            },
          ),
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DirectionCalendarPicker(
        initialDate: initialDate,
        pastDirectionDates: pastDirectionDates,
        showDragHandle: true,
        onDateSelected: (d) {
          result = d;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  return result;
}

// ── State ─────────────────────────────────────────────────────────────────────

class _DirectionCalendarPickerState extends State<DirectionCalendarPicker> {
  late DateTime _viewMonth; // mês sendo visualizado
  DateTime? _selected;

  static const _weekLetters = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  static const _monthNames = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _selected = widget.initialDate;
    _viewMonth = DateTime(base.year, base.month);
  }

  Set<String> get _pastDatesKey => widget.pastDirectionDates
      .map((d) => '${d.year}-${d.month}-${d.day}')
      .toSet();

  bool _isPast(DateTime d) =>
      _pastDatesKey.contains('${d.year}-${d.month}-${d.day}');

  void _prevMonth() => setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
      });

  /// Dias da grade: padding inicial + dias do mês.
  List<DateTime?> _buildGrid() {
    final first = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final lastDay =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // domingo=0
    return [
      ...List<DateTime?>.filled(startWeekday, null),
      ...List.generate(
        lastDay,
        (i) => DateTime(_viewMonth.year, _viewMonth.month, i + 1),
      ),
    ];
  }

  String get _confirmLabel {
    if (_selected == null) return 'selecionar data';
    final d = _selected!;
    return 'confirmar ${d.day} de ${_monthNames[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grid = _buildGrid();
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Alcinha de arrastar — omitida no modo diálogo
        if (widget.showDragHandle)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )
        else
          const SizedBox(height: 20),

        // Título
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Próxima direção',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Navegação de mês
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textSecondary,
                onPressed: _prevMonth,
                tooltip: 'Mês anterior',
              ),
              Text(
                '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textSecondary,
                onPressed: _nextMonth,
                tooltip: 'Próximo mês',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Cabeçalho dos dias da semana
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: _weekLetters
                .map(
                  (l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Grade de dias
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: grid.length,
            itemBuilder: (_, i) {
              final day = grid[i];
              if (day == null) return const SizedBox.shrink();

              final isSelected = _selected != null &&
                  day.year == _selected!.year &&
                  day.month == _selected!.month &&
                  day.day == _selected!.day;
              final isToday = day.year == today0.year &&
                  day.month == today0.month &&
                  day.day == today0.day;
              final hasDot = _isPast(day);

              return GestureDetector(
                onTap: () => setState(() => _selected = day),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: isSelected
                          ? BoxDecoration(
                              color: AppColors.rubric,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.rubric
                                    : AppColors.textPrimary,
                            fontWeight: isToday || isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    if (hasDot)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Legenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '• = direção já realizada',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Botão de confirmação
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _selected != null
                      ? AppColors.rubric
                      : AppColors.border,
                ),
                foregroundColor: AppColors.rubric,
              ),
              onPressed: _selected == null
                  ? null
                  : () => widget.onDateSelected(_selected!),
              child: Text(_confirmLabel),
            ),
          ),
        ),
      ],
    );

    // Bottom-sheet: container arredondado + SafeArea inferior
    if (widget.showDragHandle) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(top: false, child: content),
      );
    }

    // Diálogo: fundo limpo, sem borda arredondada própria (o Dialog já tem)
    return content;
  }
}
