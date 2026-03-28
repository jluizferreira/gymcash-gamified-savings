// lib/services/export_service.dart
//
// Gera e compartilha o extrato do usuário em CSV ou PDF.
// Usa share_plus para o share sheet nativo do Android/iOS.

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/contribution_model.dart';

class ExportService {
  // ── CSV ───────────────────────────────────────────────────────────────────

  /// Gera arquivo CSV e abre share sheet nativo.
  Future<void> exportCsv({
    required List<ContributionModel> contributions,
    required Map<String, String> groupNames,
    required String userName,
  }) async {
    final rows = <List<dynamic>>[
      // Cabeçalho
      ['Usuário', 'Grupo', 'Mês', 'Valor (R\$)', 'Meta (R\$)', 'Progresso'],
      // Dados
      ...contributions.map((c) => [
            userName,
            groupNames[c.groupId] ?? c.groupId,
            c.month,
            c.amount.toStringAsFixed(2),
            c.goal.toStringAsFixed(2),
            c.progressLabel,
          ]),
    ];

    final csv      = const ListToCsvConverter().convert(rows);
    final dir      = await getTemporaryDirectory();
    final fileName = 'gymcash_extrato_${_timestamp()}.csv';
    final file     = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'GymCash — Extrato de $userName',
    );
  }

  // ── PDF ───────────────────────────────────────────────────────────────────

  /// Gera arquivo PDF e abre share sheet nativo.
  Future<void> exportPdf({
    required List<ContributionModel> contributions,
    required Map<String, String> groupNames,
    required String userName,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // Paleta
    const black     = PdfColor.fromInt(0xFF0A0A0A);
    const surface   = PdfColor.fromInt(0xFF161616);
    const accent    = PdfColor.fromInt(0xFF00E676);
    const textSoft  = PdfColor.fromInt(0xFF888888);
    const white     = PdfColors.white;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          buildBackground: (ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: black),
          ),
        ),
        header: (ctx) => _buildHeader(
          userName: userName,
          font: font,
          fontBold: fontBold,
          accent: accent,
          textSoft: textSoft,
          white: white,
        ),
        footer: (ctx) => _buildFooter(
          ctx: ctx,
          font: font,
          textSoft: textSoft,
        ),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _buildTable(
            contributions: contributions,
            groupNames: groupNames,
            font: font,
            fontBold: fontBold,
            surface: surface,
            accent: accent,
            textSoft: textSoft,
            white: white,
          ),
          if (contributions.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _buildSummary(
              contributions: contributions,
              font: font,
              fontBold: fontBold,
              accent: accent,
              surface: surface,
              white: white,
              textSoft: textSoft,
            ),
          ],
        ],
      ),
    );

    final bytes    = await doc.save();
    final dir      = await getTemporaryDirectory();
    final fileName = 'gymcash_extrato_${_timestamp()}.pdf';
    final file     = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'GymCash — Extrato de $userName',
    );
  }

  // ── Widgets PDF ───────────────────────────────────────────────────────────

  pw.Widget _buildHeader({
    required String userName,
    required pw.Font font,
    required pw.Font fontBold,
    required PdfColor accent,
    required PdfColor textSoft,
    required PdfColor white,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 10,
              height: 32,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'GymCash',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 22,
                    color: white,
                  ),
                ),
                pw.Text(
                  'Extrato de $userName',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: textSoft,
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Text(
              _formatDate(DateTime.now()),
              style: pw.TextStyle(font: font, fontSize: 10, color: textSoft),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(color: const PdfColor.fromInt(0xFF222222), thickness: 1),
      ],
    );
  }

  pw.Widget _buildFooter({
    required pw.Context ctx,
    required pw.Font font,
    required PdfColor textSoft,
  }) {
    return pw.Column(
      children: [
        pw.Divider(color: const PdfColor.fromInt(0xFF222222), thickness: 1),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'GymCash — Gamificação de poupança',
              style: pw.TextStyle(font: font, fontSize: 8, color: textSoft),
            ),
            pw.Text(
              'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 8, color: textSoft),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTable({
    required List<ContributionModel> contributions,
    required Map<String, String> groupNames,
    required pw.Font font,
    required pw.Font fontBold,
    required PdfColor surface,
    required PdfColor accent,
    required PdfColor textSoft,
    required PdfColor white,
  }) {
    const headerStyle = pw.TextStyle(fontSize: 9);
    const cellStyle   = pw.TextStyle(fontSize: 9);

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5), // Grupo
        1: const pw.FlexColumnWidth(1.2), // Mês
        2: const pw.FlexColumnWidth(1.5), // Valor
        3: const pw.FlexColumnWidth(1.5), // Meta
        4: const pw.FlexColumnWidth(1.2), // Progresso
      },
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: pw.BoxDecoration(color: surface),
          children: [
            _cell('Grupo',      fontBold, white, headerStyle, isHeader: true),
            _cell('Mês',        fontBold, white, headerStyle, isHeader: true),
            _cell('Valor',      fontBold, white, headerStyle, isHeader: true),
            _cell('Meta',       fontBold, white, headerStyle, isHeader: true),
            _cell('Progresso',  fontBold, white, headerStyle, isHeader: true),
          ],
        ),
        // Linhas
        ...contributions.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final bg = i.isEven
              ? const PdfColor.fromInt(0xFF111111)
              : const PdfColor.fromInt(0xFF0A0A0A);
          final reached = c.progress >= 1.0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _cell(
                groupNames[c.groupId] ?? c.groupId,
                font, white, cellStyle,
              ),
              _cell(c.month, font, textSoft, cellStyle),
              _cell(
                'R\$ ${c.amount.toStringAsFixed(2)}',
                fontBold, white, cellStyle,
              ),
              _cell(
                'R\$ ${c.goal.toStringAsFixed(2)}',
                font, textSoft, cellStyle,
              ),
              _cell(
                c.progressLabel,
                fontBold,
                reached ? accent : white,
                cellStyle,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildSummary({
    required List<ContributionModel> contributions,
    required pw.Font font,
    required pw.Font fontBold,
    required PdfColor accent,
    required PdfColor surface,
    required PdfColor white,
    required PdfColor textSoft,
  }) {
    final total     = contributions.fold(0.0, (s, c) => s + c.amount);
    final goalsHit  = contributions.where((c) => c.progress >= 1.0).length;
    final months    = contributions.map((c) => c.month).toSet().length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: surface,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: accent,
          width: 0.5,
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total acumulado',
              'R\$ ${total.toStringAsFixed(2)}', font, fontBold, accent, white),
          _summaryItem('Meses ativos',
              '$months', font, fontBold, accent, white),
          _summaryItem('Metas atingidas',
              '$goalsHit', font, fontBold, accent, white),
        ],
      ),
    );
  }

  pw.Widget _summaryItem(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
    PdfColor accent,
    PdfColor white,
  ) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: accent)),
        pw.SizedBox(height: 4),
        pw.Text(label,
            style: pw.TextStyle(font: font, fontSize: 9, color: white)),
      ],
    );
  }

  pw.Widget _cell(
    String text,
    pw.Font font,
    PdfColor color,
    pw.TextStyle base, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: base.copyWith(font: font, color: color),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
