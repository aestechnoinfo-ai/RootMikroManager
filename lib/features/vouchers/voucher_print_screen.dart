import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'voucher_print_layout.dart';
import 'voucher_paper_format.dart';
import 'voucher_print_service.dart';
import 'voucher_template_settings.dart';

class VoucherPrintScreen extends StatelessWidget {
  final List<Map<String, String>> vouchers;
  final VoucherPrintLayout layout;
  final VoucherTemplateSettings templateSettings;

  const VoucherPrintScreen({
    super.key,
    required this.vouchers,
    this.layout = VoucherPrintLayout.qr,
    this.templateSettings = const VoucherTemplateSettings(),
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${_label(layout)} (${vouchers.length}) · '
        '${templateSettings.safeTicketsPerPage}/page',
      ),
      actions: [
        IconButton(
          tooltip: 'Imprimer / PDF',
          onPressed: vouchers.isEmpty
              ? null
              : () => Printing.layoutPdf(
                  name: 'RootMikroManager-vouchers',
                  onLayout: (format) => VoucherPrintService.buildPdf(
                    vouchers,
                    templateSettings.paperFormat.resolve(format),
                    layout: layout,
                    settings: templateSettings,
                  ),
                ),
          icon: const Icon(Icons.print_outlined),
        ),
      ],
    ),
    body: vouchers.isEmpty
        ? const Center(child: Text('Aucun voucher à afficher.'))
        : LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1200
                  ? 4
                  : constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 600
                  ? 2
                  : 1;

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  // A ratio based on width made mobile cards too short as
                  // soon as all optional voucher fields were visible.
                  mainAxisExtent: columns == 1 ? 300 : 280,
                ),
                itemCount: vouchers.length,
                itemBuilder: (context, index) => _VoucherCard(
                  voucher: vouchers[index],
                  ticketNumber: index + 1,
                  layout: layout,
                  settings: templateSettings,
                ),
              );
            },
          ),
  );

  static String _label(VoucherPrintLayout layout) => switch (layout) {
    VoucherPrintLayout.standard => 'Print Default',
    VoucherPrintLayout.qr => 'Print QR',
    VoucherPrintLayout.small => 'Print Small',
    VoucherPrintLayout.mikhmonCode => 'Compact code',
    VoucherPrintLayout.mikhmonCredentials => 'Compact ID + Pass',
  };
}

class _VoucherCard extends StatelessWidget {
  final Map<String, String> voucher;
  final int ticketNumber;
  final VoucherPrintLayout layout;
  final VoucherTemplateSettings settings;

  const _VoucherCard({
    required this.voucher,
    required this.ticketNumber,
    required this.layout,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final username = voucher['username'] ?? '—';
    final password = voucher['password'] ?? '';
    final showQr = layout == VoucherPrintLayout.qr && settings.showQr;
    final displayedHotspotName = (voucher['hotspot-name'] ?? '').trim().isEmpty
        ? settings.hotspotName.trim()
        : voucher['hotspot-name']!.trim();

    if (layout == VoucherPrintLayout.mikhmonCode ||
        layout == VoucherPrintLayout.mikhmonCredentials) {
      return _compactCard(context, username, password);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            if (showQr) ...[
              Flexible(
                flex: 2,
                child: QrImageView(
                  data: VoucherPrintService.qrPayload(
                    voucher,
                    settings: settings,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settings.showHotspotName)
                    Text(
                      displayedHotspotName.isEmpty
                          ? 'Hotspot'
                          : displayedHotspotName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  if (settings.showNumber)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('#$ticketNumber'),
                    ),
                  Text(
                    'CODE VOUCHER',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      username,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (settings.showPassword &&
                      password.isNotEmpty &&
                      password != username)
                    SelectableText('Pass: $password'),
                  if (settings.showProfile)
                    Text('Profil: ${voucher['profile'] ?? '—'}'),
                  if (settings.showValidity &&
                      (voucher['validity'] ?? '').isNotEmpty)
                    Text('Validité: ${voucher['validity']}'),
                  if (settings.showTimeLimit &&
                      (voucher['limit-uptime'] ?? '').isNotEmpty &&
                      voucher['limit-uptime'] != '0')
                    Text('Temps: ${voucher['limit-uptime']}'),
                  if (settings.showDataLimit &&
                      _dataLimit(voucher['limit-bytes-total']) != null)
                    Text('Data: ${_dataLimit(voucher['limit-bytes-total'])}'),
                  if (settings.showPrice &&
                      (voucher['selling-price'] ?? '0') != '0')
                    Text(
                      'Prix: ${voucher['selling-price']}'
                      '${settings.currency.isEmpty ? '' : ' ${settings.currency}'}',
                    ),
                  if (settings.showLoginUrl &&
                      settings.loginUrl.trim().isNotEmpty)
                    Text(
                      settings.loginUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (settings.showComment &&
                      (voucher['comment'] ?? '').isNotEmpty)
                    Text(
                      'Note: ${voucher['comment']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactCard(BuildContext context, String username, String password) {
    final credentials = layout == VoucherPrintLayout.mikhmonCredentials;
    final outline = Theme.of(context).colorScheme.outline;
    final duration = voucher['limit-uptime'] ?? '';
    final validity = voucher['validity'] ?? '';
    final displayedHotspotName = (voucher['hotspot-name'] ?? '').trim().isEmpty
        ? settings.hotspotName.trim()
        : voucher['hotspot-name']!.trim();
    final parts = <String>[
      if (settings.showTimeLimit && duration.isNotEmpty && duration != '0')
        duration,
      if (settings.showValidity && validity.isNotEmpty && validity != duration)
        validity,
      if (settings.showPrice && (voucher['selling-price'] ?? '0') != '0')
        '${voucher['selling-price']}${settings.currency.isEmpty ? '' : ' ${settings.currency}'}',
    ];

    Widget framed(Widget child) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: outline)),
      child: child,
    );

    return Card(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(border: Border.all(color: outline, width: 2)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayedHotspotName.isEmpty
                        ? 'Hotspot'
                        : displayedHotspotName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  '[$ticketNumber]',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Divider(),
            framed(
              credentials
                  ? Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            'ID: $username',
                            maxLines: 1,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText('Pass: $password', maxLines: 1),
                        ),
                      ],
                    )
                  : SelectableText(
                      'Code: $username',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
            ),
            if (parts.isNotEmpty)
              framed(
                Text(
                  parts.join(' | '),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (settings.footerText.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  settings.footerText.trim(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _dataLimit(String? raw) {
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
