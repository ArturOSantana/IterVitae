import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/entities/spiritual_direction.dart';
import '../../../domain/entities/struggle.dart' show Struggle, DailyStruggleStatus;
import '../../../domain/entities/virtue.dart';
import 'direction_state.dart';

/// Opções de conteúdo selecionadas pelo usuário antes de gerar o relatório.
class ReportOptions {
  const ReportOptions({
    this.incluirPraticas = true,
    this.incluirEstatisticas = true,
    this.incluirVirtudes = true,
    this.incluirLeituras = true,
    this.incluirQuestoes = true,
    this.incluirDiario = false, // dado sensível — desmarcado por padrão
  });

  final bool incluirPraticas;
  final bool incluirEstatisticas;
  final bool incluirVirtudes;
  final bool incluirLeituras;
  final bool incluirQuestoes;
  final bool incluirDiario;
}

/// Gera o PDF do relatório de acompanhamento para o diretor espiritual.
///
/// Visual baseado no mockup:
/// - Cabeçalho escuro com eyebrow rubrica
/// - Títulos de seção em rubrica com linha separadora
/// - Barra de fidelidade (4 px)
/// - Grade da semana da luta com dias nomeados e cores por status
/// - Cards de leitura com progresso %
/// - Caixas de nota com borda esquerda rubrica
/// - Perguntas separadas em abertas (○) e resolvidas (✓, cinza)
class DirectionReportPdf {
  const DirectionReportPdf._();

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

  // Paleta
  static const _rubric      = PdfColor.fromInt(0xFFB23A2E);
  static const _bgDark      = PdfColor.fromInt(0xFF1A1714);
  static const _bgSurface   = PdfColor.fromInt(0xFFFAF9F7);
  static const _borderColor = PdfColor.fromInt(0xFFE5E1DA);
  static const _textMain    = PdfColor.fromInt(0xFF1F2328);
  static const _textMuted   = PdfColor.fromInt(0xFFA09A92);
  static const _textBody    = PdfColor.fromInt(0xFF3D3730);

  // Status da luta — cores
  static const _achievedBg   = PdfColor.fromInt(0xFFFDE8E6);
  static const _achievedFg   = PdfColor.fromInt(0xFFB23A2E);
  static const _foughtBg     = PdfColor.fromInt(0xFFFFF8F0);
  static const _foughtFg     = PdfColor.fromInt(0xFFA85C20);
  static const _noRecordBg   = PdfColor.fromInt(0xFFF5F4F0);
  static const _noRecordFg   = PdfColor.fromInt(0xFFC0BBB5);

  static const _weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  /// Gera e retorna o [Uint8List] do documento PDF.
  static Future<Uint8List> generate(
    DirectionState state, {
    required ReportOptions options,
    Virtue? activeVirtue,
  }) async {
    final doc = pw.Document(
      title: 'Plano de Vida — Relatório de acompanhamento',
      author: 'Iter Vitae',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 52, vertical: 52),
        header: (ctx) => _pageHeader(ctx, state),
        footer: (ctx) => _pageFooter(ctx),
        build: (ctx) => _body(state, options, activeVirtue),
      ),
    );

    return doc.save();
  }

  // ── Cabeçalho de página ────────────────────────────────────────────────────

  static pw.Widget _pageHeader(pw.Context ctx, DirectionState state) {
    // Só mostra o cabeçalho completo na primeira página
    if (ctx.pageNumber > 1) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Plano de Vida — Relatório de acompanhamento (cont.)',
            style: pw.TextStyle(fontSize: 9, color: _textMuted),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.5, color: _borderColor),
          pw.SizedBox(height: 10),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Bloco escuro de cabeçalho
        pw.Container(
          width: double.infinity,
          color: _bgDark,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ITER VITAE · RELATÓRIO DE ACOMPANHAMENTO',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _rubric,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Plano de Vida — Relatório para o Diretor Espiritual',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Período: ${_dateFmt.format(state.periodFrom)} até ${_dateFmt.format(state.periodTo)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 18),
      ],
    );
  }

  // ── Rodapé de página ───────────────────────────────────────────────────────

  static pw.Widget _pageFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: _borderColor),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Iter Vitae',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            pw.Text('p. ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }

  // ── Corpo do documento ────────────────────────────────────────────────────

  static List<pw.Widget> _body(
    DirectionState state,
    ReportOptions opts,
    Virtue? virtue,
  ) {
    final widgets = <pw.Widget>[];

    // ── 1. Luta atual ──────────────────────────────────────────────────────
    final struggle = state.blockA.activeStruggle;
    if (struggle != null) {
      widgets.addAll([
        _sectionTitle('1. Luta atual'),
        pw.SizedBox(height: 8),
        _blockLabel('Tema da luta'),
        pw.SizedBox(height: 3),
        pw.Text(struggle.title,
            style: pw.TextStyle(fontSize: 11, color: _textBody)),
        pw.SizedBox(height: 10),
        _blockLabel('Registro desta semana'),
        pw.SizedBox(height: 6),
        _lutaWeekGrid(struggle),
        pw.SizedBox(height: 22),
      ]);
    }

    // ── 2. a) Formação espiritual ──────────────────────────────────────────
    final hasA = opts.incluirPraticas ||
        opts.incluirEstatisticas ||
        state.blockA.contemplateLights.isNotEmpty ||
        (state.notes.a != null && state.notes.a!.trim().isNotEmpty);

    if (hasA) {
      widgets.addAll([
        _sectionTitle('2. a) Formação espiritual'),
        pw.SizedBox(height: 8),
      ]);

      if (opts.incluirEstatisticas) {
        final pct = (state.blockA.fidelityRatio * 100).round();
        widgets.addAll([
          _blockLabel('Fidelidade às práticas espirituais'),
          pw.SizedBox(height: 4),
          _fidelityBar(pct),
          pw.SizedBox(height: 10),
        ]);
      }

      if (opts.incluirPraticas && state.blockA.spiritualPractices.isNotEmpty) {
        widgets.add(_blockLabel('Práticas'));
        widgets.add(pw.SizedBox(height: 3));
        for (final p in state.blockA.spiritualPractices) {
          final done = state.blockA.logs
              .where((l) => l.practiceId == p.id && l.completed)
              .length;
          widgets.add(_bullet('${p.name} — $done realizações no período'));
        }
        widgets.add(pw.SizedBox(height: 10));
      }

      if (state.blockA.contemplateLights.isNotEmpty) {
        widgets.add(_blockLabel('Luzes na oração mental'));
        widgets.add(pw.SizedBox(height: 3));
        for (final l in state.blockA.contemplateLights) {
          widgets.add(_bullet(l));
        }
        widgets.add(pw.SizedBox(height: 10));
      }

      if (state.notes.a != null && state.notes.a!.trim().isNotEmpty) {
        widgets.addAll([
          _blockLabel('Meios de formação e notas'),
          pw.SizedBox(height: 4),
          _noteBox(state.notes.a!),
          pw.SizedBox(height: 10),
        ]);
      }

      widgets.add(pw.SizedBox(height: 14));
    }

    // ── 3. b) Formação profissional, social e cultural ─────────────────────
    final hasB = opts.incluirLeituras && state.blockB.readingBooks.isNotEmpty ||
        (state.notes.b != null && state.notes.b!.trim().isNotEmpty);

    if (hasB) {
      widgets.addAll([
        _sectionTitle('3. b) Formação profissional, social e cultural'),
        pw.SizedBox(height: 8),
      ]);

      if (opts.incluirLeituras && state.blockB.readingBooks.isNotEmpty) {
        widgets.add(_blockLabel('Leituras em andamento'));
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(_readingTable(state.blockB.readingBooks));
        widgets.add(pw.SizedBox(height: 10));
      }

      if (state.notes.b != null && state.notes.b!.trim().isNotEmpty) {
        widgets.addAll([
          _blockLabel('Observações'),
          pw.SizedBox(height: 4),
          _noteBox(state.notes.b!),
          pw.SizedBox(height: 10),
        ]);
      }

      widgets.add(pw.SizedBox(height: 14));
    }

    // ── 4. c) Formação humana ──────────────────────────────────────────────
    final hasDiary = opts.incluirDiario && state.blockC.recentReflections.isNotEmpty;
    final hasVirtue = opts.incluirVirtudes && virtue != null;
    final hasC = hasDiary ||
        hasVirtue ||
        (state.notes.c != null && state.notes.c!.trim().isNotEmpty);

    if (hasC) {
      widgets.addAll([
        _sectionTitle('4. c) Formação humana'),
        pw.SizedBox(height: 8),
      ]);

      if (hasDiary) {
        widgets.add(_blockLabel('Reflexões do diário'));
        widgets.add(pw.SizedBox(height: 3));
        for (final r in state.blockC.recentReflections) {
          final preview =
              r.text.length > 140 ? '${r.text.substring(0, 140)}…' : r.text;
          widgets.add(_bullet('${_dateFmt.format(r.date)}: $preview'));
        }
        widgets.add(pw.SizedBox(height: 10));
      }

      if (hasVirtue) {
        widgets.addAll([
          _blockLabel('Virtude a ser exercida: ${virtue.name}'),
          pw.SizedBox(height: 4),
          _virtueBox(virtue),
          pw.SizedBox(height: 10),
        ]);
      }

      if (state.notes.c != null && state.notes.c!.trim().isNotEmpty) {
        widgets.addAll([
          _blockLabel('Notas do bloco c'),
          pw.SizedBox(height: 4),
          _noteBox(state.notes.c!),
          pw.SizedBox(height: 10),
        ]);
      }

      widgets.add(pw.SizedBox(height: 14));
    }

    // ── 5. Perguntas para a direção ────────────────────────────────────────
    if (opts.incluirQuestoes && state.questions.isNotEmpty) {
      widgets.addAll([
        _sectionTitle('5. Perguntas para a direção'),
        pw.SizedBox(height: 8),
        ..._questionsSection(state.questions),
      ]);
    }

    return widgets;
  }

  // ── Grade semanal da luta ─────────────────────────────────────────────────

  static pw.Widget _lutaWeekGrid(Struggle struggle) {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Seg
    final startOfWeek =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));

    // Monta os 7 dias com status
    final days = List.generate(7, (i) {
      final day = startOfWeek.add(Duration(days: i));
      final isFuture = day.isAfter(now);
      if (isFuture) return _DayInfo(label: _weekdayLabels[i], status: null);

      final log = struggle.dailyLogs.where((l) {
        final ld = DateTime(l.date.year, l.date.month, l.date.day);
        return ld == DateTime(day.year, day.month, day.day);
      }).firstOrNull;

      return _DayInfo(
        label: _weekdayLabels[i],
        status: log?.status,
      );
    });

    // Contagens
    final achieved = days.where((d) => d.status == DailyStruggleStatus.achieved).length;
    final fought   = days.where((d) => d.status == DailyStruggleStatus.fought).length;
    final noRecord = days.where(
      (d) => d.status == null && !days.any((x) => x.label == d.label && x.status != null),
    ).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: days
              .map((d) => pw.Expanded(child: _dayCell(d)))
              .toList(),
        ),
        pw.SizedBox(height: 8),
        // Legenda
        pw.Row(
          children: [
            _legendDot(_achievedFg),
            pw.SizedBox(width: 4),
            pw.Text('$achieved consegui',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(width: 14),
            _legendDot(_foughtFg),
            pw.SizedBox(width: 4),
            pw.Text('$fought lutei e caí',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(width: 14),
            _legendDot(_noRecordFg),
            pw.SizedBox(width: 4),
            pw.Text('$noRecord sem registro',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _dayCell(_DayInfo info) {
    final PdfColor bg;
    final PdfColor fg;
    final String symbol;

    if (info.status == null) {
      bg = _noRecordBg;
      fg = _noRecordFg;
      symbol = '—';
    } else if (info.status == DailyStruggleStatus.achieved) {
      bg = _achievedBg;
      fg = _achievedFg;
      symbol = '✓';
    } else {
      // fought ou didNotFight
      bg = _foughtBg;
      fg = _foughtFg;
      symbol = '↘';
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 2),
      height: 36,
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: info.status == DailyStruggleStatus.achieved
              ? _rubric
              : info.status == null
                  ? _borderColor
                  : _foughtFg,
          width: 0.5,
        ),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            symbol,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: fg,
            ),
          ),
          pw.Text(
            info.label,
            style: pw.TextStyle(fontSize: 7, color: _textMuted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _legendDot(PdfColor color) => pw.Container(
        width: 7,
        height: 7,
        decoration: pw.BoxDecoration(
          color: color,
          shape: pw.BoxShape.circle,
        ),
      );

  // ── Barra de fidelidade ────────────────────────────────────────────────────

  static pw.Widget _fidelityBar(int pct) {
    // Usa Row com dois Expanded proporcionais para evitar LayoutBuilder com
    // constraints nullable. O fill ocupa `pct` partes, o restante `100-pct`.
    final rest = 100 - pct.clamp(0, 100);
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Row(
            children: [
              // Fill
              pw.Expanded(
                flex: pct.clamp(0, 100),
                child: pw.Container(
                  height: 4,
                  decoration: pw.BoxDecoration(
                    color: _rubric,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
              ),
              // Track restante (só renderizado quando pct < 100)
              if (rest > 0)
                pw.Expanded(
                  flex: rest,
                  child: pw.Container(
                    height: 4,
                    decoration: pw.BoxDecoration(
                      color: _bgSurface,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          '$pct%',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _rubric,
          ),
        ),
      ],
    );
  }

  // ── Tabela de leituras ────────────────────────────────────────────────────

  static pw.Widget _readingTable(List<dynamic> books) {
    final rows = books.map((b) {
      final autor = b.author != null ? b.author as String : '';
      final pct   = (b.progressRatio * 100).round();
      return pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.5)),
        ),
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    b.title as String,
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textMain),
                  ),
                  if (autor.isNotEmpty)
                    pw.Text(autor,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ),
            pw.Text(
              '$pct%',
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: _rubric),
            ),
          ],
        ),
      );
    }).toList();

    return pw.Column(children: rows);
  }

  // ── Caixa de nota com borda rubrica ───────────────────────────────────────

  static pw.Widget _noteBox(String text) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _bgSurface,
        border: pw.Border(
          left: const pw.BorderSide(color: _rubric, width: 3),
          top: pw.BorderSide(color: _borderColor, width: 0.5),
          right: pw.BorderSide(color: _borderColor, width: 0.5),
          bottom: pw.BorderSide(color: _borderColor, width: 0.5),
        ),
        borderRadius: const pw.BorderRadius.only(
          topRight: pw.Radius.circular(4),
          bottomRight: pw.Radius.circular(4),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
      ),
    );
  }

  // ── Card de virtude ───────────────────────────────────────────────────────

  static pw.Widget _virtueBox(Virtue virtue) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _bgSurface,
        border: pw.Border.all(color: _borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            virtue.name,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _textMain,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            virtue.purpose,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          if (virtue.reflections.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ...virtue.reflections.map((r) => _bullet(r)),
          ],
        ],
      ),
    );
  }

  // ── Perguntas (abertas e resolvidas) ──────────────────────────────────────

  static List<pw.Widget> _questionsSection(List<DirectionQuestion> questions) {
    final result = <pw.Widget>[];
    final open     = questions.where((q) => !q.resolved).toList();
    final resolved = questions.where((q) => q.resolved).toList();

    if (open.isNotEmpty) {
      result.add(_blockLabel('Em aberto'));
      result.add(pw.SizedBox(height: 4));
      for (final q in open) {
        result.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('○ ',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _rubric)),
                pw.Expanded(
                  child: pw.Text(q.text,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                ),
              ],
            ),
          ),
        );
      }
      result.add(pw.SizedBox(height: 10));
    }

    if (resolved.isNotEmpty) {
      result.add(_blockLabel('Resolvidas'));
      result.add(pw.SizedBox(height: 4));
      for (final q in resolved) {
        result.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('✓ ',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
                pw.Expanded(
                  child: pw.Text(
                    q.text,
                    style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey400,
                        decoration: pw.TextDecoration.lineThrough),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return result;
  }

  // ── Primitivas de layout ──────────────────────────────────────────────────

  /// Título de seção em rubrica com linha separadora à direita.
  static pw.Widget _sectionTitle(String text) {
    return pw.Row(
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _rubric,
            letterSpacing: 0.3,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            height: 0.5,
            color: const PdfColor.fromInt(0xFFF0EDE8),
          ),
        ),
      ],
    );
  }

  /// Rótulo de sub-bloco em caps pequenas cinza.
  static pw.Widget _blockLabel(String text) => pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.6,
          color: _textMuted,
        ),
      );

  static pw.Widget _bullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(left: 10, top: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('• ',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _rubric)),
            pw.Expanded(
              child: pw.Text(text,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
            ),
          ],
        ),
      );
}

/// Dados de um dia da semana para o grid da luta.
class _DayInfo {
  const _DayInfo({required this.label, required this.status});
  final String label;
  final DailyStruggleStatus? status;
}
