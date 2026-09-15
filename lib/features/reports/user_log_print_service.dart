import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'rootmikromanager_sales_record.dart';

class UserLogPrintService {
  static Future<Uint8List> buildPdf(
    List<RootMikroManagerSalesRecord> rows,
    String period,
  ) async {
    final d = pw.Document(
      title: 'RootMikroManager User Log',
      author: 'RootMikroManager',
    );
    d.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'RootMikroManager — User Log',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Période : $period'),
            pw.Divider(),
          ],
        ),
        build: (_) => [
          pw.Text('${rows.length} connexion(s)'),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Heure',
              'Utilisateur',
              'IP',
              'MAC',
              'Validité',
            ],
            data: rows
                .map(
                  (x) => [
                    x.date,
                    x.time,
                    x.username,
                    x.address,
                    x.macAddress,
                    x.validity,
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    return d.save();
  }
}
