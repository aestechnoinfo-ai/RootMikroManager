import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/settings/app_currency_settings.dart';
import '../../core/routeros/router_session.dart';
import 'voucher_history_repository.dart';

class VoucherHistoryIntegrityScreen extends StatefulWidget {
  const VoucherHistoryIntegrityScreen({super.key});
  @override
  State<VoucherHistoryIntegrityScreen> createState() => _S();
}

class _S extends State<VoucherHistoryIntegrityScreen> {
  bool loading = true;
  String currency = '';
  List<Map<String, Object?>> rows = [];
  List<String> issues = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final db = await AppDatabase.instance.db;
    final x = await Future.wait([
      VoucherHistoryRepository(
        db,
      ).read(RouterSession.instance.activeRouter?.id),
      AppCurrencySettings.load(),
    ]);
    rows = x[0] as List<Map<String, Object?>>;
    currency = x[1] as String;
    issues = [];
    final names = <String, int>{};
    for (final r in rows) {
      final n = (r['username'] ?? '').toString();
      if (n.isEmpty)
        issues.add('Entrée historique sans username.');
      else
        names[n] = (names[n] ?? 0) + 1;
      if ((r['profile'] ?? '').toString().isEmpty)
        issues.add('$n : profil absent.');
      if (double.tryParse((r['selling_price'] ?? '0').toString()) == null)
        issues.add('$n : prix invalide.');
    }
    for (final e in names.entries.where((e) => e.value > 1))
      issues.add('${e.key} apparaît ${e.value} fois dans l’historique local.');
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Audit historique vouchers'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Entrées locales'),
                  trailing: Text('${rows.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Devise'),
                  trailing: Text(
                    currency.isEmpty ? 'non configurée' : currency,
                  ),
                ),
              ),
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Historique local cohérent.'),
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
