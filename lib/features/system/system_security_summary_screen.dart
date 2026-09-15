import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemSecuritySummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemSecuritySummaryScreen({super.key, required this.service});

  @override
  State<SystemSecuritySummaryScreen> createState() =>
      _SystemSecuritySummaryScreenState();
}

class _SystemSecuritySummaryScreenState
    extends State<SystemSecuritySummaryScreen> {
  bool loading = true;
  int users = 0;
  int enabledServices = 0;
  int disabledServices = 0;
  int trustedCertificates = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final result = await Future.wait([
      widget.service.systemUsers(),
      widget.service.ipServices(),
      widget.service.certificates(),
    ]);

    users = result[0].length;
    enabledServices = result[1]
        .where((r) => r['disabled'] != 'yes' && r['disabled'] != 'true')
        .length;
    disabledServices = result[1].length - enabledServices;
    trustedCertificates = result[2]
        .where((r) => r['trusted'] == 'yes' || r['trusted'] == 'true')
        .length;

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé sécurité'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _card('Utilisateurs RouterOS', users, Icons.people_outline),
              _card(
                'Services actifs',
                enabledServices,
                Icons.lock_open_outlined,
              ),
              _card(
                'Services désactivés',
                disabledServices,
                Icons.lock_outline,
              ),
              _card(
                'Certificats approuvés',
                trustedCertificates,
                Icons.verified_user_outlined,
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Pour limiter l’accès administratif, combinez '
                    'les restrictions d’adresse des services IP '
                    'avec des règles Firewall adaptées.',
                  ),
                ),
              ),
            ],
          ),
  );

  Widget _card(String label, int value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text('$value', style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
