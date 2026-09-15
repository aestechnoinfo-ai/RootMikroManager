import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotCookieExpiryAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotCookieExpiryAuditScreen({super.key, required this.service});
  @override
  State<HotspotCookieExpiryAuditScreen> createState() => _S();
}

class _S extends State<HotspotCookieExpiryAuditScreen> {
  bool loading = true;
  List<Map<String, String>> expired = [], cookies = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Future.wait([
      widget.service.hotspotUsersFiltered(expiredOnly: true),
      widget.service.hotspotCookies(),
    ]);
    expired = r[0];
    cookies = r[1];
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get stale {
    final names = expired.map((e) => e['name']).whereType<String>().toSet();
    return cookies.where((e) => names.contains(e['user'])).toList();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Audit cookies expirés'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Tickets expirés'),
                  trailing: Text('${expired.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Cookies liés à des tickets expirés'),
                  trailing: Text('${stale.length}'),
                ),
              ),
              if (stale.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucun cookie obsolète détecté'),
                  ),
                ),
              for (final c in stale)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cookie_outlined),
                    title: Text(c['user'] ?? '—'),
                    subtitle: Text(
                      '${c['mac-address'] ?? '—'} • expire dans ${c['expires-in'] ?? '—'}',
                    ),
                  ),
                ),
            ],
          ),
  );
}
