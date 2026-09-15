import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class ScriptDetailScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String> row;
  const ScriptDetailScreen({
    super.key,
    required this.service,
    required this.row,
  });
  @override
  State<ScriptDetailScreen> createState() => _State();
}

class _State extends State<ScriptDetailScreen> {
  bool loading = true;
  List<Map<String, String>> logs = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    logs = await widget.service.scriptRelatedLogs(widget.row['name'] ?? '');
    if (mounted) setState(() => loading = false);
  }

  Future<void> run() async {
    final id = widget.row['.id'];
    if (id == null) return;
    try {
      await widget.service.runSystemScriptAdvanced(
        id,
        useScriptPermissions: false,
      );
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Script exécuté.')));
      await load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(widget.row['name'] ?? 'Script'),
      actions: [IconButton(onPressed: run, icon: const Icon(Icons.play_arrow))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.code),
            title: Text(widget.row['name'] ?? '—'),
            subtitle: Text(
              [
                'Owner ${widget.row['owner'] ?? '—'}',
                'Run count ${widget.row['run-count'] ?? '0'}',
                if ((widget.row['last-started'] ?? '').isNotEmpty)
                  'Last ${widget.row['last-started']}',
              ].join(' • '),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.row['source'] ?? '',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text('Logs associés (${logs.length})'),
            leading: const Icon(Icons.article_outlined),
            children: [
              if (loading) const LinearProgressIndicator(),
              for (final r in logs.take(30))
                ListTile(
                  title: Text(r['message'] ?? '—'),
                  subtitle: Text('${r['time'] ?? ''} • ${r['topics'] ?? ''}'),
                ),
            ],
          ),
        ),
        for (final e in widget.row.entries.where(
          (e) => e.key != '.id' && e.key != 'source' && e.value.isNotEmpty,
        ))
          Card(
            child: ListTile(
              title: Text(e.key),
              subtitle: SelectableText(e.value),
            ),
          ),
      ],
    ),
  );
}
