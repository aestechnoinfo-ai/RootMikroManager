import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';

class SalesIntegrityAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesIntegrityAuditScreen({super.key, required this.service});
  @override
  State<SalesIntegrityAuditScreen> createState() => _S();
}

class _S extends State<SalesIntegrityAuditScreen> {
  bool loading = true;
  String currency = '';
  List<RootMikroManagerSalesRecord> rows = [];
  List<String> issues = [];
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
    currency = x[1] as String;
    rows = (x[0] as List<Map<String, String>>)
        .map(RootMikroManagerSalesRecord.fromRouterOs)
        .toList();
    analyze();
    if (mounted) setState(() => loading = false);
  }

  void analyze() {
    issues = [];
    for (final r in rows) {
      if (r.username.isEmpty)
        issues.add('Enregistrement sans username : ${r.date} ${r.time}.');
      if (r.profile.isEmpty) issues.add('${r.username}: profil absent.');
      if (r.price.trim().isEmpty || double.tryParse(r.price.trim()) == null)
        issues.add('${r.username}: prix non numérique « ${r.price} ».');
      if (r.date.isEmpty) issues.add('${r.username}: date absente.');
    }
  }

  double get total =>
      rows.where((r) => r.isValid).fold(0, (a, b) => a + b.numericPrice);
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Audit des ventes'),
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
                  trailing: Text('${rows.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Total valide'),
                  trailing: Text(AppCurrencySettings.format(total, currency)),
                ),
              ),
              if (currency.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Devise non configurée'),
                    subtitle: Text(
                      'Les montants restent valides, mais rapports et tickets seront affichés sans symbole de devise.',
                    ),
                  ),
                ),
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Structure des ventes cohérente.'),
                  ),
                ),
              for (final x in issues)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(x),
                  ),
                ),
            ],
          ),
  );
}
