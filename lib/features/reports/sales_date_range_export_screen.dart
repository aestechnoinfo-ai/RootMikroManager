import 'package:flutter/material.dart';
import '../../core/export/user_selected_export_service.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';
import 'sales_date_utils.dart';

class SalesDateRangeExportScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesDateRangeExportScreen({super.key, required this.service});
  @override
  State<SalesDateRangeExportScreen> createState() => _State();
}

class _State extends State<SalesDateRangeExportScreen> {
  DateTime start = DateTime.now().subtract(const Duration(days: 30)),
      end = DateTime.now();
  bool busy = false;
  String message = '';
  String q(String v) => '"${v.replaceAll('"', '""')}"';
  Future<void> pick(bool first) async {
    final v = await showDatePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      initialDate: first ? start : end,
    );
    if (v != null)
      setState(() {
        if (first)
          start = v;
        else
          end = v;
      });
  }

  Future<void> export() async {
    if (end.isBefore(start)) {
      setState(
        () => message = 'La date de fin doit être après la date de début.',
      );
      return;
    }
    setState(() => busy = true);
    try {
      final currency = await AppCurrencySettings.load();
      final rows = (await widget.service.rootmikromanagerSalesScripts())
          .map(RootMikroManagerSalesRecord.fromRouterOs)
          .where((r) {
            return SalesDateUtils.inRange(r.date, start, end);
          })
          .toList();
      final b = StringBuffer()
        ..writeln('Date,Time,Username,Profile,Comment,Price,Currency');
      for (final r in rows)
        b.writeln(
          [
            r.date,
            r.time,
            r.username,
            r.profile,
            r.comment,
            r.price,
            currency,
          ].map(q).join(','),
        );
      final total = rows.fold<double>(0, (s, r) => s + r.numericPrice);
      b.writeln(',,,,TOTAL,${total.toStringAsFixed(2)},${q(currency)}');
      final location = await const UserSelectedExportService().saveText(
        suggestedName:
            'sales_range_${start.year}-${start.month}-${start.day}_${end.year}-${end.month}-${end.day}.csv',
        mimeType: 'text/csv',
        content: b.toString(),
      );
      message = location == null
          ? 'Export annulé.'
          : '${rows.length} vente(s), ${AppCurrencySettings.format(total, currency)}\nFichier enregistré dans l’emplacement choisi.';
    } catch (e) {
      message = 'Erreur : $e';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Exporter ventes par période')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Début'),
          subtitle: Text('${start.day}/${start.month}/${start.year}'),
          trailing: const Icon(Icons.calendar_month_outlined),
          onTap: () => pick(true),
        ),
        ListTile(
          title: const Text('Fin'),
          subtitle: Text('${end.day}/${end.month}/${end.year}'),
          trailing: const Icon(Icons.calendar_month_outlined),
          onTap: () => pick(false),
        ),
        FilledButton.icon(
          onPressed: busy ? null : export,
          icon: const Icon(Icons.download_outlined),
          label: Text(busy ? 'Export…' : 'Exporter CSV'),
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(message),
        ],
      ],
    ),
  );
}
