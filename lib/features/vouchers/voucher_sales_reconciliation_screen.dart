import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/routeros/routeros_service.dart';
import '../reports/rootmikromanager_sales_record.dart';
import '../../core/routeros/router_session.dart';
import 'voucher_history_repository.dart';

class VoucherSalesReconciliationScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherSalesReconciliationScreen({super.key, required this.service});
  @override
  State<VoucherSalesReconciliationScreen> createState() => _S();
}

class _S extends State<VoucherSalesReconciliationScreen> {
  bool loading = true;
  List<String> onlyHistory = [], onlySales = [], priceMismatch = [];
  int historyCount = 0, salesCount = 0, matched = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final db = await AppDatabase.instance.db;
    final x = await Future.wait([
      VoucherHistoryRepository(
        db,
      ).read(RouterSession.instance.activeRouter?.id),
      widget.service.rootmikromanagerSalesScripts(),
    ]);
    final history = x[0];
    final sales = (x[1] as List<Map<String, String>>)
        .map(RootMikroManagerSalesRecord.fromRouterOs)
        .where((e) => e.username.isNotEmpty)
        .toList();
    final hm = <String, Map<String, Object?>>{
      for (final r in history)
        if ('${r['username'] ?? ''}'.isNotEmpty) '${r['username']}': r,
    };
    final sm = <String, RootMikroManagerSalesRecord>{
      for (final r in sales) r.username: r,
    };
    onlyHistory = hm.keys.where((k) => !sm.containsKey(k)).toList()..sort();
    onlySales = sm.keys.where((k) => !hm.containsKey(k)).toList()..sort();
    priceMismatch = [];
    for (final k in hm.keys.where(sm.containsKey)) {
      final hp =
          double.tryParse(
            '${hm[k]!['selling_price'] ?? '0'}'.replaceAll(',', '.'),
          ) ??
          0;
      final sp = sm[k]!.numericPrice;
      if ((hp - sp).abs() > 0.009)
        priceMismatch.add('$k : historique $hp / vente $sp');
    }
    historyCount = history.length;
    salesCount = sales.length;
    matched = hm.keys.where(sm.containsKey).length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Rapprochement vouchers / ventes'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Historique $historyCount')),
                  Chip(label: Text('Ventes $salesCount')),
                  Chip(label: Text('Rapprochés $matched')),
                ],
              ),
              const SizedBox(height: 8),
              if (onlyHistory.isEmpty &&
                  onlySales.isEmpty &&
                  priceMismatch.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text(
                      'Historique local et ventes RouterOS cohérents sur les usernames connus.',
                    ),
                  ),
                ),
              if (onlyHistory.isNotEmpty)
                _section('Historique sans vente RouterOS', onlyHistory),
              if (onlySales.isNotEmpty)
                _section('Vente RouterOS sans historique local', onlySales),
              if (priceMismatch.isNotEmpty)
                _section('Écarts de prix', priceMismatch),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Un écart ne signifie pas forcément une erreur : un ancien ticket peut avoir été importé, supprimé ou enregistré avant l’activation de l’historique local.',
                  ),
                ),
              ),
            ],
          ),
  );
  Widget _section(String title, List<String> rows) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          for (final x in rows.take(100)) Text('• $x'),
          if (rows.length > 100) Text('… ${rows.length - 100} autre(s)'),
        ],
      ),
    ),
  );
}
