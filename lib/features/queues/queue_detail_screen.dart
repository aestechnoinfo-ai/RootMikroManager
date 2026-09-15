import 'package:flutter/material.dart';

class QueueDetailScreen extends StatelessWidget {
  final String title;
  final Map<String, String> row;

  const QueueDetailScreen({super.key, required this.title, required this.row});

  @override
  Widget build(BuildContext context) {
    final entries = row.entries
        .where((e) => e.key != '.id' && e.value.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.speed_outlined),
              title: Text(row['name'] ?? title),
              subtitle: Text(
                [
                  if ((row['rate'] ?? '').isNotEmpty) 'Rate ${row['rate']}',
                  if ((row['max-limit'] ?? '').isNotEmpty)
                    'Max ${row['max-limit']}',
                ].join(' • '),
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
