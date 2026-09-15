import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class WirelessDetailScreen extends StatelessWidget {
  final RouterOsService service;
  final Map<String, String> row;
  const WirelessDetailScreen({
    super.key,
    required this.service,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final entries = row.entries
        .where(
          (e) => e.key != '.id' && !e.key.startsWith('_') && e.value.isNotEmpty,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(row['name'] ?? 'Wi‑Fi')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.wifi)),
              title: Text(row['name'] ?? '—'),
              subtitle: Text(
                [
                  row['_backend'] ?? '',
                  if ((row['ssid'] ?? row['configuration.ssid'] ?? '')
                      .isNotEmpty)
                    'SSID ${row['ssid'] ?? row['configuration.ssid']}',
                  if ((row['mac-address'] ?? '').isNotEmpty)
                    'MAC ${row['mac-address']}',
                ].where((e) => e.isNotEmpty).join(' • '),
              ),
            ),
          ),
          for (final e in entries)
            Card(
              child: ListTile(
                title: Text(e.key),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: SelectableText(e.value, textAlign: TextAlign.right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
