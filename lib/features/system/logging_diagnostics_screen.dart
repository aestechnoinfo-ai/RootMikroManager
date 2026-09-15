import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class LoggingDiagnosticsScreen extends StatefulWidget {
  final RouterOsService service;
  const LoggingDiagnosticsScreen({super.key, required this.service});
  @override
  State<LoggingDiagnosticsScreen> createState() => _S();
}

class _S extends State<LoggingDiagnosticsScreen> {
  bool loading = true;
  List<Map<String, String>> rules = [], actions = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await Future.wait([
      widget.service.loggingRules(),
      widget.service.loggingActions(),
    ]);
    rules = x[0];
    actions = x[1];
    if (mounted) setState(() => loading = false);
  }

  List<String> issues() {
    final out = <String>[];
    final names = actions.map((e) => e['name']).toSet();
    for (final r in rules) {
      if (!names.contains(r['action']))
        out.add(
          'Action introuvable pour ${r['topics'] ?? '—'} : ${r['action'] ?? '—'}',
        );
      final t = (r['topics'] ?? '').toLowerCase();
      if (t.contains('debug') || t.contains('packet') || t.contains('raw'))
        out.add('Règle potentiellement très bavarde : ${r['topics']}');
    }
    for (final a in actions.where((e) => e['target'] == 'remote')) {
      final p = a['remote-protocol'] ?? 'udp',
          f = a['remote-log-format'] ?? 'default';
      if ((p == 'tcp' || p == 'tls') && f != 'cef')
        out.add('${a['name']} : TCP/TLS nécessite CEF.');
    }
    return out;
  }

  @override
  Widget build(BuildContext c) {
    final x = issues();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic logging'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Règles'),
                    trailing: Text('${rules.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Actions'),
                    trailing: Text('${actions.length}'),
                  ),
                ),
                if (x.isEmpty)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Aucune incohérence simple détectée'),
                    ),
                  ),
                for (final s in x)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(s),
                    ),
                  ),
              ],
            ),
    );
  }
}
