import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iter_vitae/core/notifications/notification_service.dart';
import 'package:iter_vitae/core/notifications/web_notification_service.dart';
import 'package:iter_vitae/domain/entities/practice.dart';
import 'package:iter_vitae/providers.dart';

/// Estado do controller de notificações.
class NotificationState {
  const NotificationState({
    this.permissionGranted = false,
    this.scheduledIds = const {},
  });

  /// Permissão de notificação concedida pelo usuário.
  final bool permissionGranted;

  /// IDs das práticas com notificação ativa.
  final Set<String> scheduledIds;

  NotificationState copyWith({
    bool? permissionGranted,
    Set<String>? scheduledIds,
  }) {
    return NotificationState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      scheduledIds: scheduledIds ?? this.scheduledIds,
    );
  }
}

/// Sincroniza as práticas ativas do Plano de Vida com notificações locais.
///
/// Regras:
///   - Só agenda práticas com [Practice.frequency] daily ou specificDays.
///   - Para specificDays, agenda a notificação diariamente e deixa ao usuário
///     ignorar nos dias não programados (MVP — matcher de dia da semana requer
///     Android 12+ e lógica extra; simplificado para v1).
///   - Práticas desativadas têm a notificação cancelada automaticamente.
///   - Chamada [syncWithPractices] ao fazer login e ao salvar/desativar prática.
class NotificationController extends AsyncNotifier<NotificationState> {
  @override
  Future<NotificationState> build() async {
    // Observa mudanças no repositório de práticas para sincronizar
    ref.read(practiceRepositoryProvider);
    // Na web, a permissão pode já ter sido concedida em sessão anterior.
    final alreadyGranted =
        kIsWeb && WebNotificationService.instance.isGranted;
    return NotificationState(permissionGranted: alreadyGranted);
  }

  /// Solicita permissão e, se concedida, sincroniza notificações.
  Future<void> requestAndSync() async {
    final granted =
        await NotificationService.instance.requestPermission();

    state = AsyncData(state.valueOrNull?.copyWith(permissionGranted: granted) ??
        NotificationState(permissionGranted: granted));

    if (granted) await syncWithPractices();
  }

  /// Agenda notificações para todas as práticas ativas com horário definido.
  /// Cancela notificações de práticas que foram desativadas.
  Future<void> syncWithPractices() async {
    final practices =
        await ref.read(practiceRepositoryProvider).getActivePractices();

    // Cancela tudo e reagenda do zero para evitar duplicatas
    await NotificationService.instance.cancelAll();

    final scheduled = <String>{};
    for (final p in practices) {
      if (!p.active) continue;
      if (p.scheduledTime.isEmpty) continue;

      await NotificationService.instance.scheduleDaily(
        practiceId: p.id,
        title: p.name,
        scheduledTime: p.scheduledTime,
        body: _bodyForCategory(p.category),
      );
      scheduled.add(p.id);
    }

    state = AsyncData(
      (state.valueOrNull ?? const NotificationState()).copyWith(
        scheduledIds: scheduled,
      ),
    );
  }

  /// Cancela a notificação de uma prática específica (ao desativar).
  Future<void> cancelForPractice(String practiceId) async {
    await NotificationService.instance.cancel(practiceId);
    final current = state.valueOrNull ?? const NotificationState();
    state = AsyncData(
      current.copyWith(
        scheduledIds: Set<String>.from(current.scheduledIds)
          ..remove(practiceId),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _bodyForCategory(PracticeCategory category) {
    return switch (category) {
      PracticeCategory.spiritual => 'Hora da sua prática espiritual.',
      PracticeCategory.human => 'Hora da sua prática humana.',
      PracticeCategory.professional => 'Hora da sua prática profissional.',
      PracticeCategory.cultural => 'Hora da sua prática cultural.',
      PracticeCategory.apostolate => 'Hora do seu apostolado.',
    };
  }
}

/// Provider do [NotificationController].
final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, NotificationState>(
  NotificationController.new,
);
