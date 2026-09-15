import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class LoggingRuleEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const LoggingRuleEditorScreen({super.key, required this.service, this.row});
  @override
  State<LoggingRuleEditorScreen> createState() => _S();
}

class _S extends State<LoggingRuleEditorScreen> {
  late final TextEditingController topics, prefix, regex;
  String action = 'memory';
  bool enabled = true, loading = true, saving = false;
  List<String> actions = ['memory'];
  final common = [
    'info',
    'warning',
    'error',
    'critical',
    'system',
    'firewall',
    'hotspot',
    'dhcp',
    'dns',
    'wireguard',
    'wireless',
    'zerotier',
    'script',
    'debug',
    'packet',
    'raw',
  ];
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    topics = TextEditingController(text: r?['topics'] ?? 'info');
    prefix = TextEditingController(text: r?['prefix'] ?? '');
    regex = TextEditingController(text: r?['regex'] ?? '');
    action = r?['action'] ?? 'memory';
    enabled = r?['disabled'] != 'yes';
    load();
  }

  Future<void> load() async {
    actions =
        (await widget.service.loggingActions())
            .map((e) => e['name'] ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (!actions.contains(action)) actions.add(action);
    if (mounted) setState(() => loading = false);
  }

  void add(String t) {
    final x = topics.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (!x.contains(t)) x.add(t);
    topics.text = x.join(',');
    setState(() {});
  }

  bool get noisy {
    final x = topics.text.toLowerCase();
    return x.contains('debug') || x.contains('packet') || x.contains('raw');
  }

  Future<void> save() async {
    if (topics.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    final v = {
      'topics': topics.text.trim(),
      'action': action,
      'prefix': prefix.text.trim(),
      'regex': regex.text.trim(),
      'disabled': enabled ? 'no' : 'yes',
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/system/logging', v);
      else
        await widget.service.set('/system/logging', id, v);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null ? 'Ajouter règle logging' : 'Modifier règle logging',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: topics,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Topics',
                  hintText: 'ntp,debug,!packet',
                  helperText: 'Virgules pour combiner, ! pour exclure.',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in common)
                    ActionChip(label: Text(t), onPressed: () => add(t)),
                ],
              ),
              if (noisy)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'debug, packet et raw peuvent produire un volume élevé de journaux.',
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: actions.contains(action) ? action : null,
                decoration: const InputDecoration(labelText: 'Action'),
                items: actions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => action = v ?? action),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: prefix,
                decoration: const InputDecoration(labelText: 'Prefix'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: regex,
                decoration: const InputDecoration(labelText: 'Regex'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activée'),
                value: enabled,
                onChanged: (v) => setState(() => enabled = v),
              ),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
  );
  @override
  void dispose() {
    topics.dispose();
    prefix.dispose();
    regex.dispose();
    super.dispose();
  }
}
