import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotExpiryPreviewScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotExpiryPreviewScreen({super.key, required this.service});
  @override
  State<HotspotExpiryPreviewScreen> createState() => _S();
}

class _S extends State<HotspotExpiryPreviewScreen> {
  bool loading = true;
  List<Map<String, String>> users = [], cookies = [], active = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.hotspotUsersFiltered(expiredOnly: true),
      widget.service.hotspotCookies(),
      widget.service.activeUsers(),
    ]);
    users = x[0];
    cookies = x[1];
    active = x[2];
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Aperçu nettoyage expirations'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Chaque ticket expiré est comparé aux Cookies Hotspot et aux sessions actives du même utilisateur.',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Tickets expirés détectés'),
                  trailing: Text('${users.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Cookies Hotspot présents'),
                  trailing: Text('${cookies.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Sessions Hotspot actives'),
                  trailing: Text('${active.length}'),
                ),
              ),
              for (final u in users)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: Text(u['name'] ?? '—'),
                    subtitle: Text(
                      [
                        if (cookies.any((x) => x['user'] == u['name']))
                          'cookie présent',
                        if (active.any((x) => x['user'] == u['name']))
                          'session active',
                        if ((u['profile'] ?? '').isNotEmpty)
                          'profil ${u['profile']}',
                      ].join(' • '),
                    ),
                  ),
                ),
            ],
          ),
  );
}
