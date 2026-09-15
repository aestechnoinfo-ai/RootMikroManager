import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotUserSessionCleanupScreen extends StatefulWidget {
  final RouterOsService service;
  final String username;
  const HotspotUserSessionCleanupScreen({
    super.key,
    required this.service,
    required this.username,
  });
  @override
  State<HotspotUserSessionCleanupScreen> createState() => _S();
}

class _S extends State<HotspotUserSessionCleanupScreen> {
  bool running = false;
  Map<String, int>? result;
  Future<void> clean() async {
    if (running || widget.username.trim().isEmpty) return;
    setState(() => running = true);
    try {
      result = await widget.service.cleanupHotspotUserSession(
        widget.username.trim(),
      );
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Nettoyage session Hotspot')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(widget.username),
            subtitle: const Text(
              'Nettoie cookies et sessions actives sans supprimer le ticket.',
            ),
          ),
        ),
        if (result != null)
          Card(
            child: ListTile(
              title: const Text('Résultat'),
              subtitle: Text(
                '${result!['cookiesRemoved'] ?? 0} cookie(s) • ${result!['activeRemoved'] ?? 0} session(s)',
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: running ? null : clean,
          icon: const Icon(Icons.logout),
          label: const Text('Nettoyer cookies + session'),
        ),
      ],
    ),
  );
}
