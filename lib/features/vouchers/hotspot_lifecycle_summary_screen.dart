import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotLifecycleSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotLifecycleSummaryScreen({super.key, required this.service});
  @override
  State<HotspotLifecycleSummaryScreen> createState() => _S();
}

class _S extends State<HotspotLifecycleSummaryScreen> {
  bool loading = true;
  int users = 0,
      expired = 0,
      active = 0,
      cookies = 0,
      orphanCookies = 0,
      expiredWithSession = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.hotspotUsers(),
      widget.service.activeUsers(),
      widget.service.hotspotCookies(),
    ]);
    final us = x[0], ac = x[1], ck = x[2];
    users = us.length;
    active = ac.length;
    cookies = ck.length;
    final names = us.map((e) => e['name'] ?? '').toSet();
    final expiredNames = us
        .where((e) => (e['limit-uptime'] ?? '') == '1s')
        .map((e) => e['name'] ?? '')
        .toSet();
    expired = expiredNames.length;
    orphanCookies = ck.where((e) => !names.contains(e['user'] ?? '')).length;
    expiredWithSession = ac
        .where((e) => expiredNames.contains(e['user'] ?? ''))
        .length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Cycle de vie Hotspot'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _card('Tickets', users, Icons.confirmation_number_outlined),
              _card('Actifs', active, Icons.online_prediction_outlined),
              _card('Cookies', cookies, Icons.cookie_outlined),
              _card('Expirés', expired, Icons.timer_off_outlined),
              _card(
                'Cookies orphelins',
                orphanCookies,
                Icons.link_off_outlined,
              ),
              _card(
                'Expirés encore actifs',
                expiredWithSession,
                Icons.warning_amber_outlined,
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Lors d’une suppression/expiration administrative, RootMikroManager doit nettoyer le cookie et la session active avant de retirer le scheduler utilisateur puis le ticket.',
                  ),
                ),
              ),
            ],
          ),
  );
  Widget _card(String t, int n, IconData i) => Card(
    child: ListTile(leading: Icon(i), title: Text(t), trailing: Text('$n')),
  );
}
