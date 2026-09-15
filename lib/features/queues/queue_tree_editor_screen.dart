import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class QueueTreeEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const QueueTreeEditorScreen({super.key, required this.service, this.row});

  @override
  State<QueueTreeEditorScreen> createState() => _QueueTreeEditorScreenState();
}

class _QueueTreeEditorScreenState extends State<QueueTreeEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController parent;
  late final TextEditingController packetMark;
  late final TextEditingController limitAt;
  late final TextEditingController maxLimit;
  late final TextEditingController burstLimit;
  late final TextEditingController burstThreshold;
  late final TextEditingController burstTime;
  late final TextEditingController comment;
  String queue = 'default';
  int priority = 8;
  bool enabled = true;
  bool saving = false;
  List<String> queueTypes = ['default'];

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    parent = TextEditingController(text: r?['parent'] ?? 'global');
    packetMark = TextEditingController(text: r?['packet-mark'] ?? '');
    limitAt = TextEditingController(text: r?['limit-at'] ?? '0');
    maxLimit = TextEditingController(text: r?['max-limit'] ?? '0');
    burstLimit = TextEditingController(text: r?['burst-limit'] ?? '0');
    burstThreshold = TextEditingController(text: r?['burst-threshold'] ?? '0');
    burstTime = TextEditingController(text: r?['burst-time'] ?? '0s');
    comment = TextEditingController(text: r?['comment'] ?? '');
    queue = r?['queue'] ?? 'default';
    priority = int.tryParse(r?['priority'] ?? '') ?? 8;
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
    loadTypes();
  }

  Future<void> loadTypes() async {
    try {
      final rows = await widget.service.queueTypes();
      final names =
          rows
              .map((r) => (r['name'] ?? '').trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      if (!names.contains(queue)) names.insert(0, queue);
      if (mounted) setState(() => queueTypes = names);
    } catch (_) {}
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || saving) return;
    setState(() => saving = true);

    final values = <String, String>{
      'name': name.text.trim(),
      'parent': parent.text.trim().isEmpty ? 'global' : parent.text.trim(),
      'packet-mark': packetMark.text.trim(),
      'limit-at': limitAt.text.trim().isEmpty ? '0' : limitAt.text.trim(),
      'max-limit': maxLimit.text.trim().isEmpty ? '0' : maxLimit.text.trim(),
      'burst-limit': burstLimit.text.trim().isEmpty
          ? '0'
          : burstLimit.text.trim(),
      'burst-threshold': burstThreshold.text.trim().isEmpty
          ? '0'
          : burstThreshold.text.trim(),
      'burst-time': burstTime.text.trim().isEmpty
          ? '0s'
          : burstTime.text.trim(),
      'priority': '$priority',
      'queue': queue,
      'disabled': enabled ? 'no' : 'yes',
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/queue/tree', values);
      } else {
        await widget.service.set('/queue/tree', id, values);
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
        widget.row == null ? 'Ajouter Queue Tree' : 'Modifier Queue Tree',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: parent,
          decoration: const InputDecoration(
            labelText: 'Parent',
            hintText: 'global ou nom du parent',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: packetMark,
          decoration: const InputDecoration(labelText: 'Packet Mark'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(isExpanded: true, 
          value: queueTypes.contains(queue) ? queue : queueTypes.first,
          decoration: const InputDecoration(labelText: 'Queue Type'),
          items: queueTypes
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => queue = v ?? queue),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: limitAt,
          decoration: const InputDecoration(labelText: 'Limit At'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: maxLimit,
          decoration: const InputDecoration(labelText: 'Max Limit'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: burstLimit,
          decoration: const InputDecoration(labelText: 'Burst Limit'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: burstThreshold,
          decoration: const InputDecoration(labelText: 'Burst Threshold'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: burstTime,
          decoration: const InputDecoration(labelText: 'Burst Time'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(isExpanded: true, 
          value: priority,
          decoration: const InputDecoration(labelText: 'Priority'),
          items: List.generate(
            8,
            (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
          ),
          onChanged: (v) => setState(() => priority = v ?? priority),
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
  );

  @override
  void dispose() {
    name.dispose();
    parent.dispose();
    packetMark.dispose();
    limitAt.dispose();
    maxLimit.dispose();
    burstLimit.dispose();
    burstThreshold.dispose();
    burstTime.dispose();
    comment.dispose();
    super.dispose();
  }
}
