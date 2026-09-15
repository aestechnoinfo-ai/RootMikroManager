import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';

class SalesReportPrintService {
  SalesReportPrintService._();

  // A bounded row count plus single-line cells guarantees that every table
  // fits on A4, even when RouterOS comments are unusually long.
  static const int _salesRowsPerPage = 35;
  static const int _summaryRowsPerPage = 48;

  static Future<Uint8List> buildPdf({
    required List<RootMikroManagerSalesRecord> records,
    required String currency,
    required String periodLabel,
  }) async {
    final immutableRecords = List<RootMikroManagerSalesRecord>.unmodifiable(
      List<RootMikroManagerSalesRecord>.from(records, growable: false),
    );
    final document = pw.Document(
      title: 'RootMikroManager Selling Report',
      author: 'RootMikroManager',
    );

    final total = immutableRecords.fold<double>(
      0,
      (sum, record) => sum + record.numericPrice,
    );

    final profileTotals = <String, double>{};
    for (final record in immutableRecords) {
      profileTotals.update(
        record.profile,
        (value) => value + record.numericPrice,
        ifAbsent: () => record.numericPrice,
      );
    }

    final sortedProfiles = profileTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final salesChunks = _chunks(immutableRecords, _salesRowsPerPage);
    final printableSalesChunks = salesChunks.isEmpty
        ? <List<RootMikroManagerSalesRecord>>[const []]
        : salesChunks;
    final totalPages =
        printableSalesChunks.length +
        (sortedProfiles.isEmpty
            ? 0
            : (sortedProfiles.length / _summaryRowsPerPage).ceil());
    var pageNumber = 0;

    for (final chunk in printableSalesChunks) {
      final tableRows = List<List<String>>.unmodifiable(
        chunk
            .map(
              (record) => List<String>.unmodifiable([
                _cell(record.date, 14),
                _cell(record.time, 10),
                _cell(record.username, 24),
                _cell(record.profile, 18),
                _cell(record.comment, 28),
                AppCurrencySettings.formatRaw(record.price, currency),
              ]),
            )
            .toList(growable: false),
      );
      pageNumber++;
      final currentPage = pageNumber;
      document.addPage(
        _salesPage(
          recordsCount: immutableRecords.length,
          total: total,
          currency: currency,
          periodLabel: periodLabel,
          tableRows: tableRows,
          currentPage: currentPage,
          totalPages: totalPages,
        ),
      );
    }

    for (final chunk in _chunks(sortedProfiles, _summaryRowsPerPage)) {
      pageNumber++;
      final currentPage = pageNumber;
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Résumé par profil',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Période : $periodLabel'),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: const ['Profil', 'Total'],
                data: chunk
                    .map(
                      (entry) => [
                        entry.key,
                        AppCurrencySettings.format(entry.value, currency),
                      ],
                    )
                    .toList(),
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Page $currentPage / $totalPages'),
              ),
            ],
          ),
        ),
      );
    }

    return document.save();
  }

  static pw.Page _salesPage({
    required int recordsCount,
    required double total,
    required String currency,
    required String periodLabel,
    required List<List<String>> tableRows,
    required int currentPage,
    required int totalPages,
  }) => pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(24),
    build: (_) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RootMikroManager - Selling Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('Période : $periodLabel'),
        pw.Divider(),
        if (currentPage == 1) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('$recordsCount vente(s)'),
              pw.Text(
                'Total : ${AppCurrencySettings.format(total, currency)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
        ],
        pw.TableHelper.fromTextArray(
          headers: const [
            'Date',
            'Heure',
            'Utilisateur',
            'Profil',
            'Commentaire',
            'Montant',
          ],
          data: tableRows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.Spacer(),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page $currentPage / $totalPages'),
        ),
      ],
    ),
  );

  static String _cell(String value, int maxCharacters) {
    final singleLine = value.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
    if (singleLine.length <= maxCharacters) return singleLine;
    return '${singleLine.substring(0, maxCharacters - 3)}...';
  }

  static List<List<T>> _chunks<T>(List<T> values, int size) => [
    for (var start = 0; start < values.length; start += size)
      values.sublist(start, (start + size).clamp(0, values.length)),
  ];
}
