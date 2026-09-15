import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'sales_data_quality_service.dart';

class SalesDataQualityScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesDataQualityScreen({super.key, required this.service});
  @override
  State<SalesDataQualityScreen> createState() => _State();
}

class _State extends State<SalesDataQualityScreen> {
  bool loading = true;
  SalesDataQualityResult result = const SalesDataQualityResult(
    total: 0,
    invalidRecords: 0,
    invalidDates: 0,
    negativePrices: 0,
    emptyProfiles: 0,
    duplicates: 0,
  );
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    result = const SalesDataQualityService().inspect(
      await widget.service.rootmikromanagerSalesScripts(),
    );
    if (mounted) setState(() => loading = false);
  }

  Widget row(String title, int value) => Card(
    child: ListTile(
      leading: Icon(
        value == 0 ? Icons.check_circle_outline : Icons.warning_amber_outlined,
      ),
      title: Text(title),
      trailing: Text('$value'),
    ),
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Qualité des données ventes'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Lignes analysées'),
                  trailing: Text('${result.total}'),
                ),
              ),
              row('Enregistrements invalides', result.invalidRecords),
              row('Dates non reconnues', result.invalidDates),
              row('Prix négatifs', result.negativePrices),
              row('Profils absents', result.emptyProfiles),
              row('Doublons stricts', result.duplicates),
              Card(
                child: ListTile(
                  leading: Icon(
                    result.clean
                        ? Icons.verified_outlined
                        : Icons.fact_check_outlined,
                  ),
                  title: Text(
                    result.clean
                        ? 'Registre cohérent'
                        : 'Corrections ou vérifications nécessaires',
                  ),
                ),
              ),
            ],
          ),
  );
}
