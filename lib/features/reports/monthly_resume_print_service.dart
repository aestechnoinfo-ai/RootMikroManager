import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';
import 'sales_date_utils.dart';

class MonthlyResumePrintService {
  static Future<Uint8List> buildPdf(
    List<RootMikroManagerSalesRecord> rows,
    String currency,
    String period,
  ) async {
    final by = <int, List<RootMikroManagerSalesRecord>>{};
    for (final x in rows) {
      final d = SalesDateUtils.parse(x.date);
      if (d != null) by.putIfAbsent(d.day, () => []).add(x);
    }
    final days = by.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final total = rows.fold<double>(0, (s, x) => s + x.numericPrice);
    final doc = pw.Document(
      title: 'RootMikroManager Resume Report',
      author: 'RootMikroManager',
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'RootMikroManager — Resume Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(period),
            pw.Divider(),
          ],
        ),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${rows.length} voucher(s)'),
              pw.Text(
                'Total : ${AppCurrencySettings.format(total, currency)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['Jour', 'Vouchers', 'Montant'],
            data: days
                .map(
                  (e) => [
                    '${e.key}',
                    '${e.value.length}',
                    AppCurrencySettings.format(
                      e.value.fold<double>(0, (s, x) => s + x.numericPrice),
                      currency,
                    ),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
