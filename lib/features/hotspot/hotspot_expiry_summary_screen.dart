import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotExpirySummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotExpirySummaryScreen({super.key, required this.service});
  @override
  State<HotspotExpirySummaryScreen> createState() => _S();
}

class _S extends State<HotspotExpirySummaryScreen> {
  bool loading = true;
  List<int> n = [0, 0, 0, 0];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Future.wait([
      widget.service.hotspotUsersFiltered(expiredOnly: true),
      widget.service.hotspotCookies(),
      widget.service.activeUsers(),
      widget.service.hotspotServerProfiles(),
    ]);
    final names = r[0].map((e) => e['name']).whereType<String>().toSet();
    n = [
      r[0].length,
      r[1].where((e) => names.contains(e['user'])).length,
      r[2].where((e) => names.contains(e['user'])).length,
      r[3]
          .where((e) => (e['login-by'] ?? '').split(',').contains('cookie'))
          .length,
    ];
    if (mounted) setState(() => loading = false);
  }

  Widget card(String t, int v, IconData i) => Card(
    child: ListTile(leading: Icon(i), title: Text(t), trailing: Text('$v')),
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé expirations Hotspot'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              card('Tickets expirés', n[0], Icons.confirmation_number_outlined),
              card('Cookies obsolètes', n[1], Icons.cookie_outlined),
              card(
                'Sessions encore actives',
                n[2],
                Icons.online_prediction_outlined,
              ),
              card(
                'Profils utilisant login-by=cookie',
                n[3],
                Icons.login_outlined,
              ),
            ],
          ),
  );
}
