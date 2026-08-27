import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../domain/entities/meio_formacao.dart';
import '../../../../providers.dart';

/// Cadência do lembrete de confissão.
enum CadenciaConfissao {
  desativado,
  mensal,
  quinzenal,
  semanal,
}

extension CadenciaConfissaoLabel on CadenciaConfissao {
  String get label => switch (this) {
        CadenciaConfissao.desativado => 'Desativado',
        CadenciaConfissao.mensal => 'Mensal',
        CadenciaConfissao.quinzenal => 'Quinzenal',
        CadenciaConfissao.semanal => 'Semanal',
      };

  int? get diasEntreLembretes => switch (this) {
        CadenciaConfissao.desativado => null,
        CadenciaConfissao.mensal => 30,
        CadenciaConfissao.quinzenal => 15,
        CadenciaConfissao.semanal => 7,
      };
}

/// Preferências de notificações extra (além das práticas).
class NotificationPrefs {
  const NotificationPrefs({
    this.exameAtivo = false,
    this.exameHora = '22:00',
    this.direcaoAtivo = false,
    this.direcaoDiasAntes = 3,
    this.meiosAtivo = false,
    this.meiosDiasAntes = 3,
    this.cadenciaConfissao = CadenciaConfissao.desativado,
    this.angelusManha = false,
    this.angelusManhaHora = '06:00',
    this.angelusMeio = false,
    this.angelusMeioHora = '12:00',
    this.angelusTarde = false,
    this.angelusTardeHora = '18:00',
  });

  /// Notificação do Exame Diário + Luta à noite.
  final bool exameAtivo;
  final String exameHora;

  /// Aviso antes da próxima direção.
  final bool direcaoAtivo;
  final int direcaoDiasAntes;

  /// Aviso antes do próximo Meio de Formação.
  final bool meiosAtivo;
  final int meiosDiasAntes;

  /// Lembrete periódico de confissão.
  final CadenciaConfissao cadenciaConfissao;

  /// Angelus — manhã (06:00), meio-dia (12:00), tarde (18:00).
  final bool angelusManha;
  final String angelusManhaHora;
  final bool angelusMeio;
  final String angelusMeioHora;
  final bool angelusTarde;
  final String angelusTardeHora;

  NotificationPrefs copyWith({
    bool? exameAtivo,
    String? exameHora,
    bool? direcaoAtivo,
    int? direcaoDiasAntes,
    bool? meiosAtivo,
    int? meiosDiasAntes,
    CadenciaConfissao? cadenciaConfissao,
    bool? angelusManha,
    String? angelusManhaHora,
    bool? angelusMeio,
    String? angelusMeioHora,
    bool? angelusTarde,
    String? angelusTardeHora,
  }) {
    return NotificationPrefs(
      exameAtivo: exameAtivo ?? this.exameAtivo,
      exameHora: exameHora ?? this.exameHora,
      direcaoAtivo: direcaoAtivo ?? this.direcaoAtivo,
      direcaoDiasAntes: direcaoDiasAntes ?? this.direcaoDiasAntes,
      meiosAtivo: meiosAtivo ?? this.meiosAtivo,
      meiosDiasAntes: meiosDiasAntes ?? this.meiosDiasAntes,
      cadenciaConfissao: cadenciaConfissao ?? this.cadenciaConfissao,
      angelusManha: angelusManha ?? this.angelusManha,
      angelusManhaHora: angelusManhaHora ?? this.angelusManhaHora,
      angelusMeio: angelusMeio ?? this.angelusMeio,
      angelusMeioHora: angelusMeioHora ?? this.angelusMeioHora,
      angelusTarde: angelusTarde ?? this.angelusTarde,
      angelusTardeHora: angelusTardeHora ?? this.angelusTardeHora,
    );
  }
}

/// Controller das preferências de notificações extra.
///
/// Persiste com SharedPreferences. Ao salvar uma preferência, reagenda
/// automaticamente as notificações correspondentes.
class NotificationPrefsController
    extends AsyncNotifier<NotificationPrefs> {
  static const _kExameAtivo = 'notif_exame_ativo';
  static const _kExameHora = 'notif_exame_hora';
  static const _kDirecaoAtivo = 'notif_direcao_ativo';
  static const _kDirecaoDiasAntes = 'notif_direcao_dias_antes';
  static const _kMeiosAtivo = 'notif_meios_ativo';
  static const _kMeiosDiasAntes = 'notif_meios_dias_antes';
  static const _kCadenciaConfissao = 'notif_cadencia_confissao';
  static const _kAngelusManha = 'notif_angelus_manha';
  static const _kAngelusManhaHora = 'notif_angelus_manha_hora';
  static const _kAngelusMeio = 'notif_angelus_meio';
  static const _kAngelusMeioHora = 'notif_angelus_meio_hora';
  static const _kAngelusTarde = 'notif_angelus_tarde';
  static const _kAngelusTardeHora = 'notif_angelus_tarde_hora';

  @override
  Future<NotificationPrefs> build() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPrefs(
      exameAtivo: prefs.getBool(_kExameAtivo) ?? false,
      exameHora: prefs.getString(_kExameHora) ?? '22:00',
      direcaoAtivo: prefs.getBool(_kDirecaoAtivo) ?? false,
      direcaoDiasAntes: prefs.getInt(_kDirecaoDiasAntes) ?? 3,
      meiosAtivo: prefs.getBool(_kMeiosAtivo) ?? false,
      meiosDiasAntes: prefs.getInt(_kMeiosDiasAntes) ?? 3,
      cadenciaConfissao: CadenciaConfissao.values[
          prefs.getInt(_kCadenciaConfissao) ?? 0],
      angelusManha: prefs.getBool(_kAngelusManha) ?? false,
      angelusManhaHora: prefs.getString(_kAngelusManhaHora) ?? '06:00',
      angelusMeio: prefs.getBool(_kAngelusMeio) ?? false,
      angelusMeioHora: prefs.getString(_kAngelusMeioHora) ?? '12:00',
      angelusTarde: prefs.getBool(_kAngelusTarde) ?? false,
      angelusTardeHora: prefs.getString(_kAngelusTardeHora) ?? '18:00',
    );
  }

  /// Salva as preferências e reagenda notificações.
  Future<void> savePrefs(NotificationPrefs prefs) async {
    state = AsyncData(prefs);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kExameAtivo, prefs.exameAtivo);
    await p.setString(_kExameHora, prefs.exameHora);
    await p.setBool(_kDirecaoAtivo, prefs.direcaoAtivo);
    await p.setInt(_kDirecaoDiasAntes, prefs.direcaoDiasAntes);
    await p.setBool(_kMeiosAtivo, prefs.meiosAtivo);
    await p.setInt(_kMeiosDiasAntes, prefs.meiosDiasAntes);
    await p.setInt(_kCadenciaConfissao, prefs.cadenciaConfissao.index);
    await p.setBool(_kAngelusManha, prefs.angelusManha);
    await p.setString(_kAngelusManhaHora, prefs.angelusManhaHora);
    await p.setBool(_kAngelusMeio, prefs.angelusMeio);
    await p.setString(_kAngelusMeioHora, prefs.angelusMeioHora);
    await p.setBool(_kAngelusTarde, prefs.angelusTarde);
    await p.setString(_kAngelusTardeHora, prefs.angelusTardeHora);

    await _rescheduleAll(prefs);
  }

  Future<void> _rescheduleAll(NotificationPrefs prefs) async {
    final svc = NotificationService.instance;

    // ── Exame da noite ──────────────────────────────────────────────────────
    await svc.cancelById(NotificationService.kIdExame);
    if (prefs.exameAtivo) {
      await svc.scheduleDailyById(
        id: NotificationService.kIdExame,
        title: 'Exame do dia',
        body: 'Como foi seu dia diante de Deus?',
        scheduledTime: prefs.exameHora,
        channelId: 'iter_vitae_exame',
        channelName: 'Exame diário',
        channelDesc: 'Convite ao Exame e registro da Luta do dia',
      );
    }

    // ── Direção se aproximando ──────────────────────────────────────────────
    await svc.cancelById(NotificationService.kIdDirecao);
    await svc.cancelById(NotificationService.kIdDirecaoHoje);
    if (prefs.direcaoAtivo) {
      final dirRepo = ref.read(directionRepositoryProvider);
      final direction = await dirRepo.getOrCreateNext();
      final proximaData = direction.date;

      await svc.scheduleOnce(
        id: NotificationService.kIdDirecao,
        title: 'Direção espiritual em ${prefs.direcaoDiasAntes} dias',
        body: 'Prepare-se para o seu encontro de direção.',
        targetDate: proximaData.subtract(
            Duration(days: prefs.direcaoDiasAntes)),
        channelId: 'iter_vitae_direcao',
        channelName: 'Direção espiritual',
        channelDesc: 'Aviso antes da próxima direção',
      );
      await svc.scheduleOnce(
        id: NotificationService.kIdDirecaoHoje,
        title: 'Direção espiritual hoje',
        body: 'Hoje é dia de direção espiritual.',
        targetDate: proximaData,
        channelId: 'iter_vitae_direcao',
        channelName: 'Direção espiritual',
        channelDesc: 'Aviso antes da próxima direção',
      );
    }

    // ── Meios de formação ───────────────────────────────────────────────────
    await svc.cancelById(NotificationService.kIdMeios);
    await svc.cancelById(NotificationService.kIdMeiosHoje);
    if (prefs.meiosAtivo) {
      final meioRepo = ref.read(meioFormacaoRepositoryProvider);
      final proximo = await meioRepo.getProximo();
      if (proximo != null) {
        await svc.scheduleOnce(
          id: NotificationService.kIdMeios,
          title: '${proximo.tipo.label} em ${prefs.meiosDiasAntes} dias',
          body: proximo.titulo,
          targetDate: proximo.data.subtract(
              Duration(days: prefs.meiosDiasAntes)),
          channelId: 'iter_vitae_meios',
          channelName: 'Meios de formação',
          channelDesc: 'Aviso antes do próximo evento de formação',
        );
        await svc.scheduleOnce(
          id: NotificationService.kIdMeiosHoje,
          title: proximo.tipo.label,
          body: '${proximo.titulo} — hoje.',
          targetDate: proximo.data,
          channelId: 'iter_vitae_meios',
          channelName: 'Meios de formação',
          channelDesc: 'Aviso antes do próximo evento de formação',
        );
      }
    }

    // ── Confissão periódica ─────────────────────────────────────────────────
    await svc.cancelById(NotificationService.kIdConfissao);
    final dias = prefs.cadenciaConfissao.diasEntreLembretes;
    if (dias != null) {
      await svc.scheduleRecurring(
        id: NotificationService.kIdConfissao,
        title: 'Lembrete de confissão',
        body: 'Considere ir à confissão em breve.',
        intervalDays: dias,
        channelId: 'iter_vitae_confissao',
        channelName: 'Confissão',
        channelDesc: 'Lembrete periódico de confissão',
      );
    }

    // ── Angelus ─────────────────────────────────────────────────────────────
    const angelusChannel = 'iter_vitae_angelus';
    const angelusChannelName = 'Angelus';
    const angelusChannelDesc = 'Lembretes do Angelus (manhã, meio-dia e tarde)';
    const angelusTitle = 'Angelus';
    const angelusBody = 'O anjo do Senhor anunciou a Maria…';

    await svc.cancelById(NotificationService.kIdAngelusManha);
    if (prefs.angelusManha) {
      await svc.scheduleDailyById(
        id: NotificationService.kIdAngelusManha,
        title: angelusTitle,
        body: angelusBody,
        scheduledTime: prefs.angelusManhaHora,
        channelId: angelusChannel,
        channelName: angelusChannelName,
        channelDesc: angelusChannelDesc,
      );
    }

    await svc.cancelById(NotificationService.kIdAngelusMeio);
    if (prefs.angelusMeio) {
      await svc.scheduleDailyById(
        id: NotificationService.kIdAngelusMeio,
        title: angelusTitle,
        body: angelusBody,
        scheduledTime: prefs.angelusMeioHora,
        channelId: angelusChannel,
        channelName: angelusChannelName,
        channelDesc: angelusChannelDesc,
      );
    }

    await svc.cancelById(NotificationService.kIdAngelusTarde);
    if (prefs.angelusTarde) {
      await svc.scheduleDailyById(
        id: NotificationService.kIdAngelusTarde,
        title: angelusTitle,
        body: angelusBody,
        scheduledTime: prefs.angelusTardeHora,
        channelId: angelusChannel,
        channelName: angelusChannelName,
        channelDesc: angelusChannelDesc,
      );
    }
  }
}

final notificationPrefsControllerProvider =
    AsyncNotifierProvider<NotificationPrefsController, NotificationPrefs>(
  NotificationPrefsController.new,
);
