import 'package:flutter/material.dart';

class LogDetailScreen extends StatelessWidget {
  final Map<String, String> row;
  const LogDetailScreen({super.key, required this.row});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Détail log')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              row['message'] ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        for (final e in row.entries.where(
          (e) => e.key != 'message' && e.value.isNotEmpty,
        ))
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
