import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotHostDetailScreen extends StatelessWidget {
  final RouterOsService service;
  final Map<String, String> host;
  const HotspotHostDetailScreen({
    super.key,
    required this.service,
    required this.host,
  });

  @override
  Widget build(BuildContext context) {
    final entries = host.entries
        .where((e) => e.key != '.id' && e.value.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Détail Host Hotspot')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: Text(host['mac-address'] ?? 'Host'),
              subtitle: Text(host['address'] ?? ''),
            ),
          ),
          for (final e in entries)
            Card(
              child: ListTile(
                title: Text(e.key),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(e.value, textAlign: TextAlign.right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
