import 'package:flutter/material.dart';
import 'package:iter_vitae/domain/entities/practice.dart';

/// Ícone padrão de cada categoria de prática.
///
/// Substitui o emoji livre que existia antes em [Practice] — todas as
/// práticas de uma mesma categoria compartilham o mesmo ícone, garantindo
/// consistência visual em toda a listagem.
IconData practiceCategoryIcon(PracticeCategory category) {
  return switch (category) {
    PracticeCategory.spiritual => Icons.self_improvement,
    PracticeCategory.human => Icons.favorite_outline,
    PracticeCategory.professional => Icons.work_outline,
    PracticeCategory.cultural => Icons.menu_book_outlined,
    PracticeCategory.apostolate => Icons.volunteer_activism_outlined,
  };
}
