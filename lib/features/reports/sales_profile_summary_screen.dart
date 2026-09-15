import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';

class SalesProfileSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesProfileSummaryScreen({super.key, required this.service});
  @override
  State<SalesProfileSummaryScreen> createState() => _S();
}

class _S extends State<SalesProfileSummaryScreen> {
  bool loading = true;
  String currency = '';
  List<RootMikroManagerSalesRecord> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await Future.wait([
      widget.service.rootmikromanagerSalesScripts(),
      AppCurrencySettings.load(),
    ]);
    rows = (x[0] as List<Map<String, String>>)
        .map(RootMikroManagerSalesRecord.fromRouterOs)
        .where((e) => e.isValid)
        .toList();
    currency = x[1] as String;
    if (mounted) setState(() => loading = false);
  }

  Map<String, List<RootMikroManagerSalesRecord>> get groups {
    final m = <String, List<RootMikroManagerSalesRecord>>{};
    for (final r in rows) m.putIfAbsent(r.profile, () => []).add(r);
    return m;
  }

  @override
  Widget build(BuildContext c) {
    final e = groups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventes par profil'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final g in e)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: Text(g.key),
                      subtitle: Text('${g.value.length} vente(s)'),
                      trailing: Text(
                        AppCurrencySettings.format(
                          g.value.fold<double>(0, (s, x) => s + x.numericPrice),
                          currency,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
