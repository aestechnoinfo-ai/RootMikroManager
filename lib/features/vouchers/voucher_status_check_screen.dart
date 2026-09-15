import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import '../reports/rootmikromanager_sales_record.dart';
import '../../core/routeros/router_session.dart';
import 'voucher_history_repository.dart';

class VoucherStatusCheckScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherStatusCheckScreen({super.key, required this.service});
  @override
  State<VoucherStatusCheckScreen> createState() => _State();
}

class _State extends State<VoucherStatusCheckScreen> {
  final username = TextEditingController();
  bool loading = false;
  String currency = '';
  Map<String, String>? user;
  List<Map<String, String>> active = [], cookies = [], schedulers = [];
  List<Map<String, Object?>> history = [];
  List<RootMikroManagerSalesRecord> sales = [];

  Future<void> check() async {
    final name = username.text.trim();
    if (name.isEmpty) return;
    setState(() => loading = true);
    try {
      final db = await AppDatabase.instance.db;
      final values = await Future.wait([
        widget.service.hotspotUsers(),
        widget.service.activeUsers(),
        widget.service.hotspotCookies(),
        widget.service.schedulers(),
        widget.service.rootmikromanagerSalesScripts(),
        VoucherHistoryRepository(
          db,
        ).read(RouterSession.instance.activeRouter?.id, username: name),
        AppCurrencySettings.load(),
      ]);
      final users = values[0] as List<Map<String, String>>;
      user = null;
      for (final candidate in users) {
        if ((candidate['name'] ?? '') == name) {
          user = candidate;
          break;
        }
      }
      active = (values[1] as List<Map<String, String>>)
          .where((e) => (e['user'] ?? '') == name)
          .toList();
      cookies = (values[2] as List<Map<String, String>>)
          .where((e) => (e['user'] ?? '') == name)
          .toList();
      schedulers = (values[3] as List<Map<String, String>>)
          .where((e) => (e['name'] ?? '') == name)
          .toList();
      sales = (values[4] as List<Map<String, String>>)
          .map(RootMikroManagerSalesRecord.fromRouterOs)
          .where((e) => e.username == name)
          .toList();
      history = values[5] as List<Map<String, Object?>>;
      currency = values[6] as String;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget countCard(String title, int value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text('$value'),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('État d’un voucher')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        TextField(
          controller: username,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => check(),
          decoration: const InputDecoration(
            labelText: 'Username exact',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: loading ? null : check,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Vérifier'),
        ),
        if (loading) const LinearProgressIndicator(),
        if (!loading && username.text.trim().isNotEmpty) ...[
          Card(
            child: ListTile(
              leading: Icon(
                user == null
                    ? Icons.cancel_outlined
                    : Icons.confirmation_number_outlined,
              ),
              title: Text(
                user == null
                    ? 'Ticket absent du routeur'
                    : 'Ticket présent sur le routeur',
              ),
              subtitle: user == null
                  ? null
                  : Text(
                      'Profil ${user!['profile'] ?? '—'} • uptime ${user!['uptime'] ?? '—'} • limite ${user!['limit-uptime'] ?? '—'}',
                    ),
            ),
          ),
          countCard(
            'Sessions Hotspot actives',
            active.length,
            Icons.online_prediction_outlined,
          ),
          countCard('Cookies Hotspot', cookies.length, Icons.cookie_outlined),
          countCard(
            'Schedulers utilisateur',
            schedulers.length,
            Icons.schedule_outlined,
          ),
          countCard(
            'Entrées historique local',
            history.length,
            Icons.history_outlined,
          ),
          countCard(
            'Enregistrements de vente',
            sales.length,
            Icons.payments_outlined,
          ),
          if (sales.isNotEmpty)
            Card(
              child: ListTile(
                title: const Text('Dernière vente détectée'),
                subtitle: Text(
                  '${sales.first.date} ${sales.first.time} • ${sales.first.profile}',
                ),
                trailing: Text(
                  AppCurrencySettings.format(
                    sales.first.numericPrice,
                    currency,
                  ),
                ),
              ),
            ),
          if (user == null && cookies.isNotEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.warning_amber_outlined),
                title: Text('Cookie orphelin détecté'),
                subtitle: Text(
                  'Le ticket n’existe plus mais un cookie subsiste : le portail captif peut mal revenir à la page Login.',
                ),
              ),
            ),
        ],
      ],
    ),
  );
  @override
  void dispose() {
    username.dispose();
    super.dispose();
  }
}
