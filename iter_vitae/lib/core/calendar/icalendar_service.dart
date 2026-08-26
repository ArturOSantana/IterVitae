import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/meio_formacao.dart';
import '../../domain/entities/practice.dart';

/// Gera um arquivo iCalendar (.ics) a partir das práticas ativas do plano de
/// vida.
///
/// Cada prática vira um VEVENT recorrente:
/// - [PracticeFrequency.daily]       → RRULE:FREQ=DAILY
/// - [PracticeFrequency.specificDays] → RRULE:FREQ=WEEKLY;BYDAY=`<dias>`
///
/// O arquivo resultante pode ser:
///   1. Compartilhado via share_plus para "Adicionar ao Calendário" no iOS.
///   2. Enviado por e-mail / link para assinar no Google Agenda via `webcal://`.
class ICalendarService {
  /// Gera o arquivo .ics na pasta temporária do dispositivo e retorna o [File].
  Future<File> generateFile(List<Practice> practices) async {
    final content = _buildIcs(practices);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/iter_vitae_plano.ics');
    await file.writeAsString(content, flush: true);
    return file;
  }

  /// Gera um arquivo .ics com um único [MeioFormacao] e retorna o [File].
  Future<File> generateMeioFormacaoFile(MeioFormacao meio) async {
    final content = _buildIcsMeio(meio);
    final dir = await getTemporaryDirectory();
    final safe = meio.titulo
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final file = File('${dir.path}/iter_vitae_$safe.ics');
    await file.writeAsString(content, flush: true);
    return file;
  }

  String _buildIcsMeio(MeioFormacao meio) {
    final buf = StringBuffer();
    final now = _fmtDateTime(DateTime.now().toUtc());
    final dtstart = DateFormat("yyyyMMdd").format(meio.data);

    buf.writeln('BEGIN:VCALENDAR');
    buf.writeln('VERSION:2.0');
    buf.writeln('PRODID:-//Iter Vitae//Plano de Vida//PT');
    buf.writeln('CALSCALE:GREGORIAN');
    buf.writeln('METHOD:PUBLISH');
    buf.writeln('BEGIN:VEVENT');
    buf.writeln('UID:${meio.id}@iter-vitae');
    buf.writeln('DTSTAMP:$now');
    buf.writeln('DTSTART;VALUE=DATE:$dtstart');
    buf.writeln('DTEND;VALUE=DATE:$dtstart');
    buf.writeln('SUMMARY:${_escapeText(meio.titulo)}');
    buf.writeln('DESCRIPTION:${_escapeText(meio.tipo.label)}${meio.nota != null && meio.nota!.isNotEmpty ? '\\n${_escapeText(meio.nota!)}' : ''}');
    buf.writeln('STATUS:CONFIRMED');
    buf.writeln('END:VEVENT');
    buf.writeln('END:VCALENDAR');
    return buf.toString();
  }

  /// Constrói o conteúdo iCalendar completo como [String].
  String _buildIcs(List<Practice> practices) {
    final buf = StringBuffer();
    final now = _fmtDateTime(DateTime.now().toUtc());

    buf.writeln('BEGIN:VCALENDAR');
    buf.writeln('VERSION:2.0');
    buf.writeln('PRODID:-//Iter Vitae//Plano de Vida//PT');
    buf.writeln('CALSCALE:GREGORIAN');
    buf.writeln('METHOD:PUBLISH');
    buf.writeln('X-WR-CALNAME:Iter Vitae — Plano de Vida');
    buf.writeln('X-WR-TIMEZONE:America/Sao_Paulo');

    final active = practices.where((p) => p.active).toList();
    for (final practice in active) {
      _writeEvent(buf, practice, now);
    }

    buf.writeln('END:VCALENDAR');
    return buf.toString();
  }

  void _writeEvent(StringBuffer buf, Practice practice, String dtstamp) {
    final uid = '${practice.id}@iter-vitae';
    final dtstart = _buildDtStart(practice);
    final dtend = _buildDtEnd(practice);
    final rrule = _buildRRule(practice);

    buf.writeln('BEGIN:VEVENT');
    buf.writeln('UID:$uid');
    buf.writeln('DTSTAMP:$dtstamp');
    buf.writeln('DTSTART;TZID=America/Sao_Paulo:$dtstart');
    buf.writeln('DTEND;TZID=America/Sao_Paulo:$dtend');
    buf.writeln('RRULE:$rrule');
    buf.writeln('SUMMARY:${_escapeText(practice.name)}');
    buf.writeln('CATEGORIES:${_categoryLabel(practice.category)}');
    buf.writeln('STATUS:CONFIRMED');
    buf.writeln('TRANSP:TRANSPARENT');
    buf.writeln('END:VEVENT');
  }

  /// Gera DTSTART como "YYYYMMDDTHHMMSS" usando hoje como data âncora para
  /// práticas diárias, ou a próxima ocorrência relevante para dias específicos.
  String _buildDtStart(Practice practice) {
    final today = DateTime.now();
    final timeParts = practice.scheduledTime.split(':');
    final hour = int.tryParse(timeParts.elementAtOrNull(0) ?? '0') ?? 0;
    final minute = int.tryParse(timeParts.elementAtOrNull(1) ?? '0') ?? 0;

    DateTime anchor = DateTime(today.year, today.month, today.day, hour, minute);

    if (practice.frequency == PracticeFrequency.specificDays &&
        practice.weekdays.isNotEmpty) {
      // Avança até o próximo dia da semana configurado (a partir de hoje).
      for (var i = 0; i < 7; i++) {
        final candidate = anchor.add(Duration(days: i));
        if (practice.weekdays.contains(candidate.weekday)) {
          anchor = candidate;
          break;
        }
      }
    }

    return _fmtLocalDateTime(anchor);
  }

  String _buildDtEnd(Practice practice) {
    final timeParts = practice.scheduledTime.split(':');
    final hour = int.tryParse(timeParts.elementAtOrNull(0) ?? '0') ?? 0;
    final minute = int.tryParse(timeParts.elementAtOrNull(1) ?? '0') ?? 0;
    final today = DateTime.now();
    // Duração padrão: 30 minutos (pode ser personalizada no futuro).
    final start = DateTime(today.year, today.month, today.day, hour, minute);
    final end = start.add(const Duration(minutes: 30));
    return _fmtLocalDateTime(end);
  }

  String _buildRRule(Practice practice) {
    if (practice.frequency == PracticeFrequency.daily) {
      return 'FREQ=DAILY';
    }
    if (practice.weekdays.isEmpty) return 'FREQ=WEEKLY';
    final isoToByday = {1: 'MO', 2: 'TU', 3: 'WE', 4: 'TH', 5: 'FR', 6: 'SA', 7: 'SU'};
    final days = practice.weekdays.map((d) => isoToByday[d] ?? '').where((s) => s.isNotEmpty).join(',');
    return 'FREQ=WEEKLY;BYDAY=$days';
  }

  String _categoryLabel(PracticeCategory cat) {
    return switch (cat) {
      PracticeCategory.spiritual    => 'Espiritual',
      PracticeCategory.human        => 'Humana',
      PracticeCategory.professional => 'Profissional',
      PracticeCategory.cultural     => 'Cultural',
      PracticeCategory.apostolate   => 'Apostolado',
    };
  }

  String _fmtDateTime(DateTime dt) =>
      DateFormat("yyyyMMdd'T'HHmmss'Z'").format(dt);

  String _fmtLocalDateTime(DateTime dt) =>
      DateFormat("yyyyMMdd'T'HHmmss").format(dt);

  /// Escapa vírgulas, ponto-e-vírgulas e barras invertidas conforme RFC 5545.
  String _escapeText(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll(',', r'\,').replaceAll(';', r'\;');
}
