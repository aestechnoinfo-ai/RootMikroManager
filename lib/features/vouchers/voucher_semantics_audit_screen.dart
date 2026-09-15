import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/routeros/routeros_service.dart';
import '../reports/rootmikromanager_sales_record.dart';
import '../reports/sales_record_identity.dart';
import '../../core/routeros/router_session.dart';
import 'voucher_history_repository.dart';

class VoucherSemanticsAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherSemanticsAuditScreen({super.key, required this.service});

  @override
  State<VoucherSemanticsAuditScreen> createState() => _State();
}

class _State extends State<VoucherSemanticsAuditScreen> {
  bool loading = true;
  int generated = 0;
  int routerTickets = 0;
  int sales = 0;
  int duplicateSales = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final db = await AppDatabase.instance.db;
    final values = await Future.wait([
      VoucherHistoryRepository(
        db,
      ).count(RouterSession.instance.activeRouter?.id),
      widget.service.hotspotUsers(),
      widget.service.rootmikromanagerSalesScripts(),
    ]);
    generated = values[0] as int;
    routerTickets = (values[1] as List).length;

    final rows = (values[2] as List<Map<String, String>>)
        .map(RootMikroManagerSalesRecord.fromRouterOs)
        .where((e) => e.isValid)
        .toList();
    sales = rows.length;

    final seen = <String>{};
    duplicateSales = 0;
    for (final row in rows) {
      final key = const SalesRecordIdentity().strictKey(row);
      if (!seen.add(key)) duplicateSales++;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sémantique vouchers & ventes'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Historique de génération local'),
                  trailing: Text('$generated'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Tickets présents sur RouterOS'),
                  trailing: Text('$routerTickets'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Événements de vente valides'),
                  trailing: Text('$sales'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Doublons stricts de vente'),
                  trailing: Text('$duplicateSales'),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Règle : génération ≠ vente ≠ réimpression. '
                    'L’historique local mémorise les tickets générés ; '
                    'le registre RouterOS mémorise les événements de vente '
                    'prévus par le profil ; une réimpression ne doit créer '
                    'ni ticket ni événement de vente.',
                  ),
                ),
              ),
            ],
          ),
  );
}
