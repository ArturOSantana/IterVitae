import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/diary_entry.dart';
import '../../../../providers.dart';

/// Estado do controller do Diário.
class DiaryState {
  const DiaryState({
    required this.entries,
    this.isSaving = false,
  });

  final List<DiaryEntry> entries;
  final bool isSaving;

  DiaryState copyWith({List<DiaryEntry>? entries, bool? isSaving}) {
    return DiaryState(
      entries: entries ?? this.entries,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Controller do Diário.
class DiaryController extends AsyncNotifier<DiaryState> {
  @override
  Future<DiaryState> build() async {
    final entries = await ref.watch(diaryRepositoryProvider).getAll();
    return DiaryState(entries: entries);
  }

  /// Salva uma nova entrada (ou atualiza existente).
  ///
  /// [tags] e [date] são opcionais — quando omitidos usa lista vazia e [DateTime.now()].
  /// Usado pela tela Meios de formação para registrar eventos com tags específicas.
  Future<void> save(
    String text, {
    String? existingId,
    List<String> tags = const [],
    DateTime? date,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true));

    final now = date ?? DateTime.now();
    final entry = DiaryEntry(
      id: existingId ?? 'diary_${now.millisecondsSinceEpoch}',
      date: now,
      text: text,
      tags: tags,
    );

    try {
      await ref.read(diaryRepositoryProvider).save(entry);
      // Recarrega a lista
      final updated = await ref.read(diaryRepositoryProvider).getAll();
      state = AsyncData(DiaryState(entries: updated));
    } catch (_) {
      state = AsyncData(current.copyWith(isSaving: false));
    }
  }

  /// Remove uma entrada pelo id.
  Future<void> delete(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Otimista
    final optimistic = current.entries.where((e) => e.id != id).toList();
    state = AsyncData(current.copyWith(entries: optimistic));

    try {
      await ref.read(diaryRepositoryProvider).delete(id);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

/// Provider do [DiaryController].
final diaryControllerProvider =
    AsyncNotifierProvider<DiaryController, DiaryState>(DiaryController.new);
