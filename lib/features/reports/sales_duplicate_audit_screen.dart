import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';

class SalesDuplicateAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesDuplicateAuditScreen({super.key, required this.service});
  @override
  State<SalesDuplicateAuditScreen> createState() => _State();
}

class _State extends State<SalesDuplicateAuditScreen> {
  bool loading = true;
  String currency = '';
  List<RootMikroManagerSalesRecord> rows = [];
  Map<String, List<RootMikroManagerSalesRecord>> duplicates = {};
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
    final groups = <String, List<RootMikroManagerSalesRecord>>{};
    for (final r in rows) {
      final key = '${r.date}|${r.time}|${r.username}|${r.price}|${r.profile}';
      groups.putIfAbsent(key, () => []).add(r);
    }
    duplicates = Map.fromEntries(
      groups.entries.where((e) => e.value.length > 1),
    );
    if (mounted) setState(() => loading = false);
  }

  double get duplicatedAmount => duplicates.values.fold(
    0,
    (s, g) => s + g.skip(1).fold<double>(0, (a, r) => a + r.numericPrice),
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Doublons des ventes'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Enregistrements analysés'),
                  trailing: Text('${rows.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Groupes dupliqués'),
                  trailing: Text('${duplicates.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Montant potentiellement doublé'),
                  trailing: Text(
                    AppCurrencySettings.format(duplicatedAmount, currency),
                  ),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Cet audit est non destructif. Les doublons doivent être vérifiés avant toute suppression, notamment pour les anciens profils dont le script de vente a pu évoluer.',
                  ),
                ),
              ),
              if (duplicates.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucun doublon strict détecté.'),
                  ),
                ),
              for (final e in duplicates.entries)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.copy_all_outlined),
                    title: Text(
                      '${e.value.first.username} × ${e.value.length}',
                    ),
                    subtitle: Text(
                      '${e.value.first.date} ${e.value.first.time} • ${e.value.first.profile}',
                    ),
                    trailing: Text(
                      AppCurrencySettings.format(
                        e.value.first.numericPrice,
                        currency,
                      ),
                    ),
                  ),
                ),
            ],
          ),
  );
}
