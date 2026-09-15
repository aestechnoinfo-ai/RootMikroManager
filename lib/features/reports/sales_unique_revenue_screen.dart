import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'sales_unique_revenue_service.dart';

class SalesUniqueRevenueScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesUniqueRevenueScreen({super.key, required this.service});

  @override
  State<SalesUniqueRevenueScreen> createState() => _State();
}

class _State extends State<SalesUniqueRevenueScreen> {
  bool loading = true;
  String currency = '';
  SalesUniqueRevenueResult result = const SalesUniqueRevenueResult(
    rawCount: 0,
    validCount: 0,
    uniqueCount: 0,
    duplicateCount: 0,
    uniqueRevenue: 0,
  );

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
    result = const SalesUniqueRevenueService().calculate(
      values[0] as List<Map<String, String>>,
    );
    currency = values[1] as String;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('CA dédupliqué'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Lignes brutes'),
                  trailing: Text('${result.rawCount}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Ventes valides'),
                  trailing: Text('${result.validCount}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Ventes uniques'),
                  trailing: Text('${result.uniqueCount}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Doublons exclus'),
                  trailing: Text('${result.duplicateCount}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Chiffre d’affaires dédupliqué'),
                  trailing: Text(
                    AppCurrencySettings.format(result.uniqueRevenue, currency),
                  ),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Le calcul exclut uniquement les doublons stricts '
                    'date + heure + username + prix + profil. '
                    'Aucune donnée RouterOS n’est supprimée.',
                  ),
                ),
              ),
            ],
          ),
  );
}
