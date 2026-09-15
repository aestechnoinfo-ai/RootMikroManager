import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SimpleQueueEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const SimpleQueueEditorScreen({super.key, required this.service, this.row});

  @override
  State<SimpleQueueEditorScreen> createState() =>
      _SimpleQueueEditorScreenState();
}

class _SimpleQueueEditorScreenState extends State<SimpleQueueEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController target;
  late final TextEditingController maxLimit;
  late final TextEditingController limitAt;
  late final TextEditingController burstLimit;
  late final TextEditingController burstThreshold;
  late final TextEditingController burstTime;
  late final TextEditingController priority;
  late final TextEditingController parent;
  late final TextEditingController comment;
  bool enabled = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final row = widget.row;
    name = TextEditingController(text: row?['name'] ?? '');
    target = TextEditingController(text: row?['target'] ?? '');
    maxLimit = TextEditingController(text: row?['max-limit'] ?? '');
    limitAt = TextEditingController(text: row?['limit-at'] ?? '');
    burstLimit = TextEditingController(text: row?['burst-limit'] ?? '');
    burstThreshold = TextEditingController(text: row?['burst-threshold'] ?? '');
    burstTime = TextEditingController(text: row?['burst-time'] ?? '');
    priority = TextEditingController(text: row?['priority'] ?? '8/8');
    parent = TextEditingController(text: row?['parent'] ?? 'none');
    comment = TextEditingController(text: row?['comment'] ?? '');
    enabled = row?['disabled'] != 'true' && row?['disabled'] != 'yes';
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || saving) return;
    setState(() => saving = true);

    final values = <String, String>{
      'name': name.text.trim(),
      'target': target.text.trim(),
      'disabled': enabled ? 'no' : 'yes',
      if (maxLimit.text.trim().isNotEmpty) 'max-limit': maxLimit.text.trim(),
      if (limitAt.text.trim().isNotEmpty) 'limit-at': limitAt.text.trim(),
      if (burstLimit.text.trim().isNotEmpty)
        'burst-limit': burstLimit.text.trim(),
      if (burstThreshold.text.trim().isNotEmpty)
        'burst-threshold': burstThreshold.text.trim(),
      if (burstTime.text.trim().isNotEmpty) 'burst-time': burstTime.text.trim(),
      if (priority.text.trim().isNotEmpty) 'priority': priority.text.trim(),
      if (parent.text.trim().isNotEmpty) 'parent': parent.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/queue/simple', values);
      } else {
        await widget.service.set('/queue/simple', id, values);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null ? 'Ajouter Simple Queue' : 'Modifier Simple Queue',
      ),
    ),
    body: Form(
      key: formKey,
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
          TextFormField(
            controller: target,
            decoration: const InputDecoration(
              labelText: 'Target *',
              hintText: '192.168.88.10/32',
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Target obligatoire' : null,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: maxLimit,
            decoration: const InputDecoration(
              labelText: 'Max limit',
              hintText: '10M/10M',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: limitAt,
            decoration: const InputDecoration(
              labelText: 'Limit at',
              hintText: '2M/2M',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: burstLimit,
            decoration: const InputDecoration(labelText: 'Burst limit'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: burstThreshold,
            decoration: const InputDecoration(labelText: 'Burst threshold'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: burstTime,
            decoration: const InputDecoration(labelText: 'Burst time'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: priority,
            decoration: const InputDecoration(labelText: 'Priority'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: parent,
            decoration: const InputDecoration(labelText: 'Parent'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: comment,
            decoration: const InputDecoration(labelText: 'Commentaire'),
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
    ),
  );

  @override
  void dispose() {
    name.dispose();
    target.dispose();
    maxLimit.dispose();
    limitAt.dispose();
    burstLimit.dispose();
    burstThreshold.dispose();
    burstTime.dispose();
    priority.dispose();
    parent.dispose();
    comment.dispose();
    super.dispose();
  }
}
