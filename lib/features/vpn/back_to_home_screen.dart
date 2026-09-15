import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class BackToHomeScreen extends StatefulWidget {
  final RouterOsService service;
  const BackToHomeScreen({super.key, required this.service});

  @override
  State<BackToHomeScreen> createState() => _BackToHomeScreenState();
}

class _BackToHomeScreenState extends State<BackToHomeScreen> {
  bool loading = true;
  Map<String, String> cloud = {};
  List<Map<String, String>> users = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      cloud = await widget.service.backToHomeStatus();
    } catch (_) {
      cloud = {};
    }
    try {
      users = await widget.service.backToHomeUsers();
    } catch (_) {
      users = [];
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Back to Home'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: const Text('État VPN'),
                  subtitle: Text(
                    [
                      'VPN ${cloud['back-to-home-vpn'] ?? '—'}',
                      if ((cloud['vpn-status'] ?? '').isNotEmpty)
                        cloud['vpn-status']!,
                      if ((cloud['vpn-dns-name'] ?? '').isNotEmpty)
                        cloud['vpn-dns-name']!,
                    ].join(' • '),
                  ),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Back to Home est affiché ici principalement pour '
                    'l’administration et le diagnostic. La configuration '
                    'initiale reste normalement réalisée avec '
                    'l’application Back to Home.',
                  ),
                ),
              ),
              Text(
                'Utilisateurs (${users.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final r in users)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(r['name'] ?? 'Utilisateur'),
                    subtitle: Text(
                      [
                        if ((r['client-address'] ?? '').isNotEmpty)
                          r['client-address']!,
                        'LAN ${r['allow-lan'] ?? 'no'}',
                        if ((r['expires'] ?? '').isNotEmpty)
                          'Expire ${r['expires']}',
                        if ((r['active'] ?? '').isNotEmpty)
                          'Active ${r['active']}',
                      ].join(' • '),
                    ),
                  ),
                ),
            ],
          ),
  );
}
