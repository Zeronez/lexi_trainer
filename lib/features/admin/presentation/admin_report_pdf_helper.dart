import 'dart:typed_data';

import 'package:lexi_trainer/features/admin/data/models/admin_report_metrics.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminReportPdfHelper {
  const AdminReportPdfHelper._();

  static Future<Uint8List> build({
    required AdminReportMetrics metrics,
    required DateTime generatedAt,
  }) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(18),
              border: pw.Border.all(color: PdfColors.blueGrey200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey900,
                    borderRadius: pw.BorderRadius.circular(14),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '\u041e\u0442\u0447\u0435\u0442 \u043f\u043e \u043e\u0441\u043d\u043e\u0432\u043d\u044b\u043c \u043c\u0435\u0442\u0440\u0438\u043a\u0430\u043c',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '\u0414\u0430\u0442\u0430 \u0444\u043e\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u044f: ${_formatGeneratedAt(generatedAt)}',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.blueGrey100,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                ..._buildMetricLines(metrics).map((line) => _MetricRow(line)),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.blueGrey200),
                pw.SizedBox(height: 8),
                pw.Text(
                  '\u041e\u0442\u0447\u0435\u0442 \u0441\u0444\u043e\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u043d \u0430\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438 \u043d\u0430 \u043e\u0441\u043d\u043e\u0432\u0435 \u0442\u0435\u043a\u0443\u0449\u0438\u0445 \u0434\u0430\u043d\u043d\u044b\u0445 \u0441\u0438\u0441\u0442\u0435\u043c\u044b.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.blueGrey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static List<_MetricLine> _buildMetricLines(AdminReportMetrics metrics) {
    return [
      _MetricLine(
        title:
            '\u041a\u043e\u043b\u0438\u0447\u0435\u0441\u0442\u0432\u043e \u0434\u043e\u0441\u0442\u0443\u043f\u043d\u044b\u0445 \u0441\u043b\u043e\u0432\u0430\u0440\u043d\u044b\u0445 \u043d\u0430\u0431\u043e\u0440\u043e\u0432',
        value: metrics.vocabularySetCount.toString(),
      ),
      _MetricLine(
        title:
            '\u041a\u043e\u043b\u0438\u0447\u0435\u0441\u0442\u0432\u043e \u043d\u0430\u0437\u043d\u0430\u0447\u0435\u043d\u043d\u044b\u0445 \u0437\u0430\u0434\u0430\u043d\u0438\u0439',
        value: metrics.taskCount.toString(),
      ),
      _MetricLine(
        title:
            '\u041a\u043e\u043b\u0438\u0447\u0435\u0441\u0442\u0432\u043e \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u043d\u044b\u0445 \u0437\u0430\u0434\u0430\u043d\u0438\u0439',
        value: metrics.completedTaskCount.toString(),
      ),
      _MetricLine(
        title:
            '\u0421\u0440\u0435\u0434\u043d\u044f\u044f \u0442\u043e\u0447\u043d\u043e\u0441\u0442\u044c \u043e\u0442\u0432\u0435\u0442\u043e\u0432',
        value: _formatPercent(metrics.averageAnswerAccuracyPercent),
      ),
      _MetricLine(
        title:
            '\u041a\u043e\u043b\u0438\u0447\u0435\u0441\u0442\u0432\u043e \u0430\u043a\u0442\u0438\u0432\u043d\u044b\u0445 \u0441\u0442\u0443\u0434\u0435\u043d\u0442\u043e\u0432',
        value: metrics.activeStudentCount.toString(),
      ),
    ];
  }
}

class _MetricLine {
  const _MetricLine({required this.title, required this.value});

  final String title;
  final String value;
}

class _MetricRow extends pw.StatelessWidget {
  _MetricRow(this.line);

  final _MetricLine line;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColors.blueGrey100),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              line.title,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.blueGrey800,
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Text(
            line.value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatGeneratedAt(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_twoDigits(local.day)}.${_twoDigits(local.month)}.${local.year} '
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

String _formatPercent(double value) {
  return '${value.toStringAsFixed(1).replaceAll('.', ',')} %';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
