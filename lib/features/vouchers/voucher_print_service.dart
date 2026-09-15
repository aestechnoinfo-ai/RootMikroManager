import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'voucher_print_layout.dart';
import 'voucher_template_settings.dart';
import 'voucher_print_density_policy.dart';
import 'voucher_portal_url_validator.dart';

class VoucherPrintService {
  static String qrPayload(
    Map<String, String> voucher, {
    VoucherTemplateSettings settings = const VoucherTemplateSettings(),
  }) {
    final user = voucher['username'] ?? '';
    final password = voucher['password'] ?? '';
    if (settings.loginUrl.trim().isNotEmpty &&
        const VoucherPortalUrlValidator().validate(settings.loginUrl).isEmpty) {
      return const VoucherPortalUrlValidator().buildQrPayload(
        loginUrl: settings.loginUrl,
        username: user,
        password: password,
      );
    }

    final profile = voucher['profile'] ?? '';
    return 'RootMikroManager|username=$user|password=$password'
        '|profile=$profile';
  }

  static Future<Uint8List> buildPdf(
    List<Map<String, String>> vouchers,
    PdfPageFormat format, {
    VoucherPrintLayout layout = VoucherPrintLayout.qr,
    VoucherTemplateSettings settings = const VoucherTemplateSettings(),
  }) async {
    final document = pw.Document(
      title: 'RootMikroManager Vouchers',
      author: 'RootMikroManager',
    );

    final perPage = const VoucherPrintDensityPolicy().effectivePerPage(
      settings.paperFormat,
      settings.safeTicketsPerPage,
    );
    final pages = <List<Map<String, String>>>[];
    for (var i = 0; i < vouchers.length; i += perPage) {
      pages.add(vouchers.sublist(i, math.min(i + perPage, vouchers.length)));
    }

    if (pages.isEmpty) pages.add(const []);

    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final chunk = pages[pageIndex];
      document.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(10),
          build: (context) {
            final grid = _gridFor(perPage);
            final isMikhmonCompact =
                layout == VoucherPrintLayout.mikhmonCode ||
                layout == VoucherPrintLayout.mikhmonCredentials;
            final rowHeight = isMikhmonCompact
                ? (format.height - 20) / grid.rows
                : null;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                if (!isMikhmonCompact &&
                    (settings.showTitle || settings.showHotspotName))
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Text(
                      [
                        if (settings.showTitle) settings.title,
                        if (settings.showHotspotName) settings.hotspotName,
                      ].where((e) => e.trim().isNotEmpty).join(' — '),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: perPage >= 30 ? 7 : 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.Expanded(
                  child: pw.Table(
                    columnWidths: {
                      for (var column = 0; column < grid.columns; column++)
                        column: const pw.FlexColumnWidth(),
                    },
                    border: pw.TableBorder.symmetric(
                      inside: const pw.BorderSide(width: 0.15),
                    ),
                    children: _tableRows(
                      chunk,
                      grid.columns,
                      perPage,
                      layout,
                      settings,
                      pageIndex * perPage,
                      rowHeight: rowHeight,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return document.save();
  }

  static ({int columns, int rows}) _gridFor(int perPage) {
    if (perPage <= 2) return (columns: 1, rows: 2);
    if (perPage <= 6) return (columns: 2, rows: 3);
    if (perPage <= 12) return (columns: 3, rows: 4);
    if (perPage <= 20) return (columns: 4, rows: 5);
    if (perPage <= 30) return (columns: 5, rows: 6);
    if (perPage <= 40) return (columns: 5, rows: 8);
    return (columns: 5, rows: 10);
  }

  static List<pw.TableRow> _tableRows(
    List<Map<String, String>> vouchers,
    int columns,
    int density,
    VoucherPrintLayout layout,
    VoucherTemplateSettings settings,
    int offset, {
    double? rowHeight,
  }) {
    final rows = <pw.TableRow>[];
    for (var i = 0; i < vouchers.length; i += columns) {
      final cells = <pw.Widget>[];
      for (var c = 0; c < columns; c++) {
        final index = i + c;
        if (index >= vouchers.length) {
          cells.add(pw.SizedBox(height: rowHeight));
        } else {
          cells.add(
            pw.SizedBox(
              height: rowHeight,
              child: _card(
                vouchers[index],
                layout,
                settings,
                density: density,
                ticketNumber: offset + index + 1,
              ),
            ),
          );
        }
      }
      rows.add(pw.TableRow(children: cells));
    }
    return rows;
  }

  static pw.Widget _card(
    Map<String, String> voucher,
    VoucherPrintLayout layout,
    VoucherTemplateSettings settings, {
    required int density,
    required int ticketNumber,
  }) {
    final compact = density >= 25 || layout == VoucherPrintLayout.small;
    final veryDense = density >= 40;
    final showQr =
        layout == VoucherPrintLayout.qr &&
        const VoucherPrintDensityPolicy().shouldRenderQr(
          format: settings.paperFormat,
          ticketsPerPage: density,
          qrEnabled: settings.showQr,
        );
    final base = veryDense
        ? 4.5
        : compact
        ? 5.5
        : 7.0;
    final codeSize = veryDense
        ? 10.0
        : compact
        ? 12.0
        : 16.0;
    final username = voucher['username'] ?? '—';
    final password = voucher['password'] ?? '';
    final displayedHotspotName = (voucher['hotspot-name'] ?? '').trim().isEmpty
        ? settings.hotspotName.trim()
        : voucher['hotspot-name']!.trim();

    if (layout == VoucherPrintLayout.mikhmonCode ||
        layout == VoucherPrintLayout.mikhmonCredentials) {
      return _mikhmonCard(
        voucher,
        settings,
        credentials: layout == VoucherPrintLayout.mikhmonCredentials,
        ticketNumber: ticketNumber,
        density: density,
      );
    }

    final details = <pw.Widget>[];

    if (settings.showPassword && password.isNotEmpty && password != username) {
      details.add(_line('Pass', password, base));
    }
    if (settings.showProfile) {
      details.add(_line('Profil', voucher['profile'] ?? '—', base));
    }
    if (settings.showValidity && (voucher['validity'] ?? '').isNotEmpty) {
      details.add(_line('Validité', voucher['validity']!, base));
    }
    if (settings.showTimeLimit &&
        (voucher['limit-uptime'] ?? '').isNotEmpty &&
        voucher['limit-uptime'] != '0') {
      details.add(_line('Temps', voucher['limit-uptime']!, base));
    }
    if (settings.showDataLimit) {
      final formatted = _formatBytes(voucher['limit-bytes-total']);
      if (formatted != null) details.add(_line('Data', formatted, base));
    }
    if (settings.showPrice && (voucher['selling-price'] ?? '0') != '0') {
      final price =
          '${voucher['selling-price']}'
          '${settings.currency.isEmpty ? '' : ' ${settings.currency}'}';
      details.add(_line('Prix', price, base));
    }
    if (settings.showLoginUrl && settings.loginUrl.trim().isNotEmpty) {
      details.add(
        pw.Text(
          settings.loginUrl,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(fontSize: math.max(4.0, base - 1)),
        ),
      );
    }
    if (settings.showComment && (voucher['comment'] ?? '').isNotEmpty) {
      details.add(_line('Note', voucher['comment']!, base));
    }

    return pw.Padding(
      padding: pw.EdgeInsets.all(
        veryDense
            ? 2
            : compact
            ? 3
            : 5,
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (settings.showHotspotName)
            pw.Text(
              displayedHotspotName.isEmpty ? 'Hotspot' : displayedHotspotName,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: math.max(base, 6),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          if (settings.showNumber)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                '#$ticketNumber',
                style: pw.TextStyle(fontSize: math.max(4.0, base - 1)),
              ),
            ),
          pw.Text(
            'CODE VOUCHER',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: base, fontWeight: pw.FontWeight.bold),
          ),
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 2),
            padding: pw.EdgeInsets.symmetric(
              vertical: veryDense ? 2 : 3,
              horizontal: 2,
            ),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.7)),
            child: pw.Text(
              username,
              textAlign: pw.TextAlign.center,
              maxLines: 1,
              style: pw.TextStyle(
                fontSize: codeSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (showQr && !veryDense)
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrPayload(voucher, settings: settings),
                width: compact ? 24 : 38,
                height: compact ? 24 : 38,
              ),
            ),
          ...details,
        ],
      ),
    );
  }

  static pw.Widget _mikhmonCard(
    Map<String, String> voucher,
    VoucherTemplateSettings settings, {
    required bool credentials,
    required int ticketNumber,
    required int density,
  }) {
    final dense = density >= 25;
    final textSize = dense ? 5.5 : 8.0;
    final codeSize = dense ? 7.0 : 11.0;
    final username = voucher['username'] ?? '—';
    final password = voucher['password'] ?? '';
    final displayedHotspotName = (voucher['hotspot-name'] ?? '').trim().isEmpty
        ? settings.hotspotName.trim()
        : voucher['hotspot-name']!.trim();
    final summary = _ticketSummary(voucher, settings);

    pw.Widget framed(pw.Widget child) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 2),
      padding: pw.EdgeInsets.symmetric(vertical: dense ? 1 : 2, horizontal: 2),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: child,
    );

    return pw.Container(
      margin: const pw.EdgeInsets.all(1.5),
      padding: pw.EdgeInsets.all(dense ? 2 : 4),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  displayedHotspotName.isEmpty
                      ? 'Hotspot'
                      : displayedHotspotName,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontSize: codeSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                '[$ticketNumber]',
                style: pw.TextStyle(
                  fontSize: codeSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Divider(height: 3, thickness: 0.5),
          if (credentials)
            framed(
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'ID: $username',
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(
                        fontSize: codeSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 3),
                  pw.Expanded(
                    child: pw.Text(
                      'Pass: $password',
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(fontSize: textSize),
                    ),
                  ),
                ],
              ),
            )
          else
            framed(
              pw.Text(
                'Code: $username',
                textAlign: pw.TextAlign.center,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: codeSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          if (summary.isNotEmpty)
            framed(
              pw.Text(
                summary,
                textAlign: pw.TextAlign.center,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: textSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          if (settings.footerText.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                settings.footerText.trim(),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(fontSize: textSize),
              ),
            ),
        ],
      ),
    );
  }

  static String _ticketSummary(
    Map<String, String> voucher,
    VoucherTemplateSettings settings,
  ) {
    final values = <String>[];
    final duration = voucher['limit-uptime'] ?? '';
    final validity = voucher['validity'] ?? '';
    if (settings.showTimeLimit && duration.isNotEmpty && duration != '0') {
      values.add(duration);
    }
    if (settings.showValidity && validity.isNotEmpty && validity != duration) {
      values.add(validity);
    }
    if (settings.showPrice && (voucher['selling-price'] ?? '0') != '0') {
      values.add(
        '${voucher['selling-price']}${settings.currency.isEmpty ? '' : ' ${settings.currency}'}',
      );
    }
    return values.join(' | ');
  }

  static pw.Widget _line(String label, String value, double size) => pw.Text(
    '$label: $value',
    maxLines: 1,
    overflow: pw.TextOverflow.clip,
    style: pw.TextStyle(fontSize: size),
  );

  static String? _formatBytes(String? raw) {
    final bytes = int.tryParse(raw ?? '') ?? 0;
    if (bytes <= 0) return null;
    if (bytes >= 1073741824 && bytes % 1073741824 == 0) {
      return '${bytes ~/ 1073741824} GB';
    }
    if (bytes >= 1048576 && bytes % 1048576 == 0) {
      return '${bytes ~/ 1048576} MB';
    }
    return '$bytes B';
  }
}
