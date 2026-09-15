import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotExpiredCleanupScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotExpiredCleanupScreen({super.key, required this.service});
  @override
  State<HotspotExpiredCleanupScreen> createState() => _S();
}

class _S extends State<HotspotExpiredCleanupScreen> {
  bool running = false;
  Map<String, int>? last;
  Future<void> run() async {
    if (running) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Nettoyer les tickets expirés ?'),
            content: const Text(
              'Pour chaque ticket expiré, RootMikroManager supprimera d’abord les cookies Hotspot du même utilisateur et déconnectera ses sessions actives, puis supprimera le ticket.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Nettoyer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    setState(() => running = true);
    try {
      last = await widget.service.cleanupExpiredHotspotUsers();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Nettoyage tickets expirés')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Ordre appliqué : cookies → sessions actives → schedulers utilisateurs → tickets expirés. Le client peut ainsi revenir au portail captif au lieu de réutiliser un cookie obsolète.',
            ),
          ),
        ),
        if (last != null) ...[
          Card(
            child: ListTile(
              title: const Text('Tickets trouvés'),
              trailing: Text('${last!['usersMatched'] ?? 0}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Cookies supprimés'),
              trailing: Text('${last!['cookiesRemoved'] ?? 0}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Sessions déconnectées'),
              trailing: Text('${last!['activeRemoved'] ?? 0}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Schedulers supprimés'),
              trailing: Text('${last!['schedulersRemoved'] ?? 0}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Tickets supprimés'),
              trailing: Text('${last!['usersRemoved'] ?? 0}'),
            ),
          ),
        ],
        FilledButton.icon(
          onPressed: running ? null : run,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: const Text('Nettoyer maintenant'),
        ),
      ],
    ),
  );
}
