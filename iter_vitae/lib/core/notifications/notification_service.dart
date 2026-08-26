import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Serviço centralizado de notificações locais.
///
/// Responsabilidades:
///   - Inicializar o plugin uma única vez ao abrir o app
///   - Agendar notificações diárias recorrentes por prática
///   - Agendar notificações pontuais (uma vez) e periódicas
///   - Cancelar notificações individualmente ou em bloco
///
/// Singleton simples — não depende de Riverpod.
/// O [NotificationController] (Riverpod) orquestra quando chamar este serviço.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // ── IDs reservados para notificações extras ────────────────────────────────
  static const int kIdExame = 10000;
  static const int kIdDirecao = 10001;
  static const int kIdDirecaoHoje = 10002;
  static const int kIdMeios = 10003;
  static const int kIdMeiosHoje = 10004;
  static const int kIdConfissao = 10005;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Inicialização ──────────────────────────────────────────────────────────

  /// Deve ser chamado uma vez em [main], antes de runApp.
  Future<void> init() async {
    if (_initialized) return;

    // Notificações locais não funcionam na web (plugin retorna null silencioso)
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Solicita permissão ao usuário (iOS / Android 13+).
  /// Chamado no cold start, logo após [init].
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    return false;
  }

  // ── Agendamento ────────────────────────────────────────────────────────────

  /// Agenda uma notificação diária recorrente para [practiceId].
  ///
  /// [scheduledTime] no formato "HH:mm" (ex.: "07:30").
  /// [title] é o nome da prática; [body] é o subtítulo.
  Future<void> scheduleDaily({
    required String practiceId,
    required String title,
    required String scheduledTime,
    String body = 'Hora da sua prática.',
  }) async {
    if (kIsWeb || !_initialized) return;

    final parts = scheduledTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    final id = _idForPractice(practiceId);
    final now = tz.TZDateTime.now(tz.local);

    // Próxima ocorrência do horário (hoje ou amanhã se já passou)
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'iter_vitae_practices',
      'Práticas do dia',
      channelDescription: 'Lembretes das práticas do Plano de Vida',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repete todo dia
    );
  }

  /// Agenda uma notificação diária recorrente pelo [id] numérico.
  ///
  /// Usado para notificações extra (Exame, etc.) que não são práticas.
  Future<void> scheduleDailyById({
    required int id,
    required String title,
    required String body,
    required String scheduledTime,
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) async {
    if (kIsWeb || !_initialized) return;

    final parts = scheduledTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final details = _buildDetails(
        channelId: channelId,
        channelName: channelName,
        channelDesc: channelDesc);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Agenda uma notificação para um instante específico (dispara uma vez).
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime targetDate,
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) async {
    if (kIsWeb || !_initialized) return;

    final now = DateTime.now();
    if (targetDate.isBefore(now)) return; // data passada — nada a agendar

    final scheduled = tz.TZDateTime.from(targetDate, tz.local);
    final details = _buildDetails(
        channelId: channelId,
        channelName: channelName,
        channelDesc: channelDesc);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Agenda um lembrete recorrente a cada [intervalDays] dias a partir de hoje.
  ///
  /// Implementado como notificação diária no mesmo horário (09:00) reagendada
  /// a cada disparo — suficiente para MVP.
  Future<void> scheduleRecurring({
    required int id,
    required String title,
    required String body,
    required int intervalDays,
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) async {
    if (kIsWeb || !_initialized) return;

    final now = tz.TZDateTime.now(tz.local);
    // Agenda para daqui a [intervalDays] dias às 09:00
    final targetDay = now.add(Duration(days: intervalDays));
    final scheduled = tz.TZDateTime(
      tz.local,
      targetDay.year,
      targetDay.month,
      targetDay.day,
      9,
      0,
    );

    final details = _buildDetails(
        channelId: channelId,
        channelName: channelName,
        channelDesc: channelDesc);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancela a notificação de [practiceId].
  Future<void> cancel(String practiceId) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id: _idForPractice(practiceId));
  }

  /// Cancela uma notificação pelo [id] numérico.
  Future<void> cancelById(int id) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id: id);
  }

  /// Cancela todas as notificações agendadas pelo app.
  Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails();
    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  /// Converte o [practiceId] (String) num int de 31 bits para o plugin.
  int _idForPractice(String practiceId) =>
      practiceId.hashCode & 0x7FFFFFFF;
}
