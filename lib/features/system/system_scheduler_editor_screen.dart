import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemSchedulerEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const SystemSchedulerEditorScreen({
    super.key,
    required this.service,
    this.row,
  });
  @override
  State<SystemSchedulerEditorScreen> createState() => _State();
}

class _State extends State<SystemSchedulerEditorScreen> {
  static const policies = [
    'ftp',
    'reboot',
    'read',
    'write',
    'policy',
    'test',
    'password',
    'sniff',
    'sensitive',
    'romon',
  ];
  final key = GlobalKey<FormState>();
  late final TextEditingController name,
      startDate,
      startTime,
      interval,
      onEvent,
      comment;
  final selected = <String>{};
  bool enabled = true, saving = false, loading = true;
  List<String> scripts = [];
  String directScript = '';
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    startDate = TextEditingController(text: r?['start-date'] ?? '');
    startTime = TextEditingController(text: r?['start-time'] ?? '00:00:00');
    interval = TextEditingController(text: r?['interval'] ?? '0s');
    onEvent = TextEditingController(text: r?['on-event'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
    selected.addAll(
      (r?['policy'] ?? '')
          .split(',')
          .map((e) => e.trim())
          .where(policies.contains),
    );
    if (widget.row == null) selected.addAll(['read', 'write', 'test']);
    load();
  }

  Future<void> load() async {
    scripts =
        (await widget.service.scripts())
            .map((e) => e['name'] ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    if (scripts.contains(onEvent.text.trim()))
      directScript = onEvent.text.trim();
    if (mounted) setState(() => loading = false);
  }

  bool validTime(String v) {
    if (v == 'startup') return true;
    return RegExp(r'^(?:[01]?\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$').hasMatch(v);
  }

  bool validInterval(String v) =>
      RegExp(r'^(?:0s|(?:\d+(?:ms|s|m|h|d|w))+)$').hasMatch(v.trim());
  bool validDate(String v) =>
      v.isEmpty ||
      RegExp(
        r'^(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/\d{1,2}/\d{4}$',
        caseSensitive: false,
      ).hasMatch(v.trim());
  Future<void> save() async {
    if (!(key.currentState?.validate() ?? false) || saving) return;
    if (!validTime(startTime.text.trim())) {
      note('Start Time invalide. Utilisez HH:mm:ss ou startup.');
      return;
    }
    if (!validInterval(
      interval.text.trim().isEmpty ? '0s' : interval.text.trim(),
    )) {
      note('Interval invalide. Exemples : 0s, 5m, 1h, 1d.');
      return;
    }
    if (!validDate(startDate.text.trim())) {
      note('Start Date invalide. Exemple : sep/01/2026.');
      return;
    }
    if (startTime.text.trim() == 'startup' && interval.text.trim() != '0s')
      note(
        'Avec startup + interval non nul, le Scheduler ne s’exécute pas au démarrage ; il attend l’intervalle.',
      );
    setState(() => saving = true);
    final v = <String, String>{
      'name': name.text.trim(),
      'start-time': startTime.text.trim().isEmpty
          ? '00:00:00'
          : startTime.text.trim(),
      'interval': interval.text.trim().isEmpty ? '0s' : interval.text.trim(),
      'on-event': onEvent.text,
      'policy': selected.join(','),
      'disabled': enabled ? 'no' : 'yes',
      'comment': comment.text.trim(),
      if (startDate.text.trim().isNotEmpty) 'start-date': startDate.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/system/scheduler', v);
      else
        await widget.service.set('/system/scheduler', id, v);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        note('$e');
        setState(() => saving = false);
      }
    }
  }

  void note(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null ? 'Nouveau Scheduler' : 'Modifier Scheduler',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: key,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Nom obligatoire' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(isExpanded: true, 
                  value: directScript.isEmpty ? null : directScript,
                  decoration: const InputDecoration(
                    labelText: 'Script direct (optionnel)',
                  ),
                  items: scripts
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => directScript = v ?? '');
                    if (v != null) onEvent.text = v;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: startDate,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    hintText: 'sep/01/2026',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: startTime,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    hintText: '00:00:00 ou startup',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: interval,
                  decoration: const InputDecoration(
                    labelText: 'Interval',
                    hintText: '0s, 5m, 1h, 1d',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: onEvent,
                  minLines: 5,
                  maxLines: 16,
                  decoration: const InputDecoration(
                    labelText: 'On Event *',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'On Event obligatoire' : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Policies Scheduler',
                  style: Theme.of(c).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final p in policies)
                      FilterChip(
                        label: Text(p),
                        selected: selected.contains(p),
                        onSelected: (v) => setState(
                          () => v ? selected.add(p) : selected.remove(p),
                        ),
                      ),
                  ],
                ),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Un Scheduler qui exécute une commande inline utilise ses propres policies. Un Scheduler qui appelle directement un script peut être limité par les permissions du script selon la méthode d’appel.',
                    ),
                  ),
                ),
                TextField(
                  controller: comment,
                  decoration: const InputDecoration(labelText: 'Commentaire'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activé'),
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
          ),
  );
  @override
  void dispose() {
    for (final c in [name, startDate, startTime, interval, onEvent, comment])
      c.dispose();
    super.dispose();
  }
}
