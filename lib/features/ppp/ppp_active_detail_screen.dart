import 'package:flutter/material.dart';

class PppActiveDetailScreen extends StatelessWidget {
  final Map<String, String> row;
  const PppActiveDetailScreen({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final entries = row.entries
        .where((e) => e.key != '.id' && e.value.isNotEmpty)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(row['name'] ?? 'Session PPP')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.lan_outlined)),
              title: Text(row['name'] ?? '—'),
              subtitle: Text(
                [
                  row['service'] ?? '',
                  row['address'] ?? '',
                  row['uptime'] ?? '',
                ].where((e) => e.isNotEmpty).join(' • '),
              ),
            ),
          ),
          for (final e in entries)
            Card(
              child: ListTile(
                title: Text(e.key),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: SelectableText(e.value, textAlign: TextAlign.right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
