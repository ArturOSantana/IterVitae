import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/calendar/icalendar_service.dart';
import '../../../../providers.dart';

/// Estado do export de calendário.
class CalendarExportState {
  const CalendarExportState({
    this.isLoading = false,
    this.lastFile,
    this.error,
  });

  final bool isLoading;
  final File? lastFile;
  final String? error;

  CalendarExportState copyWith({
    bool? isLoading,
    File? lastFile,
    String? error,
  }) =>
      CalendarExportState(
        isLoading: isLoading ?? this.isLoading,
        lastFile: lastFile ?? this.lastFile,
        error: error,
      );
}

/// Controller responsável por gerar o arquivo .ics e acioná-lo via share_plus.
class CalendarExportController extends Notifier<CalendarExportState> {
  @override
  CalendarExportState build() => const CalendarExportState();

  final _service = ICalendarService();

  /// Gera o .ics com todas as práticas ativas e abre o seletor nativo de
  /// compartilhamento / adição ao calendário.
  Future<void> exportAndShare() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final practiceRepo = ref.read(practiceRepositoryProvider);
      final practices = await practiceRepo.getAllPractices();
      final active = practices.where((p) => p.active).toList();

      if (active.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Nenhuma prática ativa para exportar.',
        );
        return;
      }

      final file = await _service.generateFile(active);
      state = state.copyWith(isLoading: false, lastFile: file);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/calendar')],
        subject: 'Iter Vitae — Plano de Vida',
        text: 'Adicione as práticas do seu Plano de Vida ao calendário.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Não foi possível gerar o arquivo. Tente novamente.',
      );
    }
  }
}

final calendarExportControllerProvider =
    NotifierProvider<CalendarExportController, CalendarExportState>(
  CalendarExportController.new,
);
