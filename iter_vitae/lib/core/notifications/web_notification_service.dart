// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Wrapper minimalista sobre a Web Notifications API.
///
/// Funciona apenas em [kIsWeb]. Em outras plataformas todos os métodos são
/// no-ops.
///
/// A API nativa do browser não suporta agendamento — usamos [Timer]s em
/// memória para disparar notificações no horário configurado. Os timers são
/// perdidos ao recarregar a página, que é o comportamento esperado para PWA
/// sem service-worker de background.
class WebNotificationService {
  WebNotificationService._();
  static final WebNotificationService instance = WebNotificationService._();

  // Timers ativos por ID numérico (notificações extras) ou por practiceId.
  final Map<String, Timer> _timers = {};

  // ── Permissão ─────────────────────────────────────────────────────────────

  /// Retorna `true` se a permissão já foi concedida, sem pedir ao usuário.
  bool get isGranted {
    if (!kIsWeb) return false;
    return _Notification.permission == 'granted';
  }

  /// Solicita permissão ao usuário. Retorna `true` se concedida.
  Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
    if (isGranted) return true;
    final result = await _Notification.requestPermission().toDart;
    return result.toDart == 'granted';
  }

  // ── Exibição imediata ─────────────────────────────────────────────────────

  /// Exibe uma notificação imediatamente (se permissão concedida).
  void showNow(String title, {String body = ''}) {
    if (!kIsWeb || !isGranted) return;
    _Notification(title, _NotificationOptions(body: body));
  }

  // ── Agendamento por horário diário (HH:mm) ────────────────────────────────

  /// Agenda uma notificação diária no horário [scheduledTime] ("HH:mm").
  ///
  /// O timer é reiniciado a cada disparo para simular recorrência durante
  /// o ciclo de vida da página.
  void scheduleDaily({
    required String id,
    required String title,
    String body = '',
    required String scheduledTime,
  }) {
    if (!kIsWeb || !isGranted) return;
    _timers[id]?.cancel();

    final parts = scheduledTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    void schedule() {
      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, hour, minute);
      if (!target.isAfter(now)) {
        target = target.add(const Duration(days: 1));
      }
      final delay = target.difference(now);
      _timers[id] = Timer(delay, () {
        showNow(title, body: body);
        schedule(); // reagenda para o dia seguinte
      });
    }

    schedule();
  }

  /// Agenda uma notificação para uma data/hora específica (dispara uma vez).
  void scheduleOnce({
    required String id,
    required String title,
    String body = '',
    required DateTime targetDate,
  }) {
    if (!kIsWeb || !isGranted) return;
    final now = DateTime.now();
    if (!targetDate.isAfter(now)) return;

    _timers[id]?.cancel();
    final delay = targetDate.difference(now);
    _timers[id] = Timer(delay, () {
      showNow(title, body: body);
      _timers.remove(id);
    });
  }

  /// Cancela o timer/notificação de [id].
  void cancel(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
  }

  /// Cancela todos os timers.
  void cancelAll() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }
}

// ── JS Interop ────────────────────────────────────────────────────────────────

@JS('Notification')
extension type _Notification._(JSObject _) implements JSObject {
  external factory _Notification(String title, _NotificationOptions options);

  @JS('permission')
  external static String get permission;

  @JS('requestPermission')
  external static JSPromise<JSString> requestPermission();
}

@JS()
@anonymous
extension type _NotificationOptions._(JSObject _) implements JSObject {
  external factory _NotificationOptions({String body});
}
