import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import '../vouchers/voucher_sales_ledger_service.dart';
import 'rootmikromanager_sales_record.dart';

class SalesConsistencySummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesConsistencySummaryScreen({super.key, required this.service});
  @override
  State<SalesConsistencySummaryScreen> createState() => _State();
}

class _State extends State<SalesConsistencySummaryScreen> {
  bool loading = true;
  String currency = '';
  int raw = 0;
  int unique = 0;
  int duplicates = 0;
  int invalid = 0;
  double revenue = 0;

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
    final records = rows.map(RootMikroManagerSalesRecord.fromRouterOs).toList();
    final valid = records.where((e) => e.isValid).toList();
    final ledger = const VoucherSalesLedgerService();
    final entries = ledger.normalize(valid);
    raw = records.length;
    invalid = records.length - valid.length;
    duplicates = ledger.duplicateCount(entries);
    unique = entries.where((e) => !e.duplicate).length;
    revenue = ledger.uniqueRevenue(entries);
    currency = values[1] as String;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cohérence des ventes'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Enregistrements RouterOS'),
                  trailing: Text('$raw'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Ventes uniques'),
                  trailing: Text('$unique'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Doublons stricts'),
                  trailing: Text('$duplicates'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Lignes invalides'),
                  trailing: Text('$invalid'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('CA retenu'),
                  trailing: Text(AppCurrencySettings.format(revenue, currency)),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Une réimpression n’est jamais comptée comme une '
                    'nouvelle vente. Le CA repose uniquement sur les '
                    'enregistrements de vente valides et non dupliqués.',
                  ),
                ),
              ),
            ],
          ),
  );
}
