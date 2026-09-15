import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';
import 'sales_date_utils.dart';

class SalesRetentionAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesRetentionAuditScreen({super.key, required this.service});

  @override
  State<SalesRetentionAuditScreen> createState() => _State();
}

class _State extends State<SalesRetentionAuditScreen> {
  bool loading = true;
  int total = 0;
  int dated = 0;
  int invalidDate = 0;
  DateTime? oldest;
  DateTime? newest;
  double revenue = 0;
  String currency = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final values = await Future.wait([
      widget.service.rootmikromanagerSalesScripts(),
      AppCurrencySettings.load(),
    ]);

    final rows = values[0] as List<Map<String, String>>;
    currency = values[1] as String;
    total = rows.length;
    dated = 0;
    invalidDate = 0;
    revenue = 0;
    oldest = null;
    newest = null;

    for (final row in rows) {
      final record = RootMikroManagerSalesRecord.fromRouterOs(row);
      if (record.isValid) revenue += record.numericPrice;
      final date = SalesDateUtils.parse(record.date);
      if (date == null) {
        invalidDate++;
        continue;
      }
      dated++;
      if (oldest == null || date.isBefore(oldest!)) oldest = date;
      if (newest == null || date.isAfter(newest!)) newest = date;
    }

    if (mounted) setState(() => loading = false);
  }

  String format(DateTime? value) => value == null
      ? '—'
      : '${value.day.toString().padLeft(2, '0')}/'
            '${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Audit conservation des ventes'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Enregistrements'),
                  trailing: Text('$total'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Dates reconnues'),
                  trailing: Text('$dated'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Dates non reconnues'),
                  trailing: Text('$invalidDate'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Plus ancienne vente'),
                  trailing: Text(format(oldest)),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Plus récente vente'),
                  trailing: Text(format(newest)),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Montant brut historique'),
                  trailing: Text(AppCurrencySettings.format(revenue, currency)),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Cet audit est non destructif. La suppression des '
                    'anciennes données reste une action explicite dans '
                    'Nettoyage des ventes.',
                  ),
                ),
              ),
            ],
          ),
  );
}
