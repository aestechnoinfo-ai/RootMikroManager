import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SchedulerDetailScreen extends StatelessWidget {
  final RouterOsService service;
  final Map<String, String> row;

  const SchedulerDetailScreen({
    super.key,
    required this.service,
    required this.row,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(row['name'] ?? 'Scheduler')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.event_repeat_outlined),
            title: Text(row['name'] ?? '—'),
            subtitle: Text(
              [
                'Start ${row['start-date'] ?? ''} '
                    '${row['start-time'] ?? ''}',
                'Next ${row['next-run'] ?? '—'}',
                'Interval ${row['interval'] ?? '0s'}',
                'Run count ${row['run-count'] ?? '0'}',
              ].join(' • '),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              row['on-event'] ?? '',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        for (final e in row.entries.where(
          (e) => e.key != '.id' && e.key != 'on-event' && e.value.isNotEmpty,
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
