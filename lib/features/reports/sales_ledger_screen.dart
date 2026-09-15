import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import '../vouchers/voucher_sales_ledger_service.dart';
import 'rootmikromanager_sales_record.dart';

class SalesLedgerScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesLedgerScreen({super.key, required this.service});
  @override
  State<SalesLedgerScreen> createState() => _S();
}

class _S extends State<SalesLedgerScreen> {
  final ledger = const VoucherSalesLedgerService();
  bool loading = true;
  String currency = '';
  List<VoucherSalesLedgerEntry> entries = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.rootmikromanagerSalesScripts(),
      AppCurrencySettings.load(),
    ]);
    final records = (x[0] as List<Map<String, String>>)
        .map(RootMikroManagerSalesRecord.fromRouterOs)
        .toList();
    entries = ledger.normalize(records);
    currency = x[1] as String;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Registre des ventes'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Ventes uniques'),
                  trailing: Text(
                    '${entries.where((e) => !e.duplicate).length}',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Doublons détectés'),
                  trailing: Text('${ledger.duplicateCount(entries)}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('CA sans doublons'),
                  trailing: Text(
                    AppCurrencySettings.format(
                      ledger.uniqueRevenue(entries),
                      currency,
                    ),
                  ),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'La réimpression d’un voucher ne crée pas une vente. Ce registre déduplique uniquement les enregistrements de vente strictement identiques ; aucune ligne RouterOS n’est supprimée automatiquement.',
                  ),
                ),
              ),
              for (final e in entries)
                Card(
                  child: ListTile(
                    leading: Icon(
                      e.duplicate
                          ? Icons.copy_all_outlined
                          : Icons.payments_outlined,
                    ),
                    title: Text(e.username),
                    subtitle: Text('${e.profile} • ${e.date} ${e.time}'),
                    trailing: Text(
                      AppCurrencySettings.format(e.amount, currency),
                    ),
                  ),
                ),
            ],
          ),
  );
}
