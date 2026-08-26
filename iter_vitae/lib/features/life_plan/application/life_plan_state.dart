import 'package:iter_vitae/domain/entities/practice.dart';

/// Estado da tela Regra de Vida.
class LifePlanState {
  const LifePlanState({required this.practices});

  /// Todas as práticas (ativas + inativas), para exibição completa.
  final List<Practice> practices;

  /// Práticas ativas agrupadas por categoria, na ordem canônica.
  Map<PracticeCategory, List<Practice>> get grouped {
    final result = <PracticeCategory, List<Practice>>{};
    for (final cat in _categoryOrder) {
      final items = practices
          .where((p) => p.active && p.category == cat)
          .toList()
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      if (items.isNotEmpty) result[cat] = items;
    }
    return result;
  }

  LifePlanState copyWith({List<Practice>? practices}) =>
      LifePlanState(practices: practices ?? this.practices);
}

/// Ordem de exibição das categorias na lista.
const _categoryOrder = [
  PracticeCategory.spiritual,
  PracticeCategory.human,
  PracticeCategory.professional,
  PracticeCategory.cultural,
  PracticeCategory.apostolate,
];
