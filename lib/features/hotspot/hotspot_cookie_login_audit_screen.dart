import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotCookieLoginAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotCookieLoginAuditScreen({super.key, required this.service});
  @override
  State<HotspotCookieLoginAuditScreen> createState() => _S();
}

class _S extends State<HotspotCookieLoginAuditScreen> {
  bool loading = true;
  List<Map<String, String>> profiles = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    profiles = await widget.service.hotspotServerProfiles();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Audit login-by Cookie')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Quand login-by contient cookie, RouterOS peut reconnecter automatiquement le navigateur tant que le cookie reste valide. Le nettoyage à expiration devient donc essentiel.',
                  ),
                ),
              ),
              for (final p in profiles)
                Card(
                  child: ListTile(
                    leading: Icon(
                      (p['login-by'] ?? '').split(',').contains('cookie')
                          ? Icons.cookie_outlined
                          : Icons.login_outlined,
                    ),
                    title: Text(p['name'] ?? '—'),
                    subtitle: Text(
                      'login-by ${p['login-by'] ?? '—'} • cookie lifetime ${p['http-cookie-lifetime'] ?? '—'}',
                    ),
                  ),
                ),
            ],
          ),
  );
}
