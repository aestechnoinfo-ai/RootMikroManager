import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class InterfaceListEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const InterfaceListEditorScreen({super.key, required this.service, this.row});
  @override
  State<InterfaceListEditorScreen> createState() => _State();
}

class _State extends State<InterfaceListEditorScreen> {
  static const builtIns = {'all', 'none', 'dynamic', 'static'};
  late final TextEditingController name, include, exclude;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.row?['name'] ?? '');
    include = TextEditingController(text: widget.row?['include'] ?? '');
    exclude = TextEditingController(text: widget.row?['exclude'] ?? '');
  }

  Future<void> save() async {
    final n = name.text.trim();
    if (n.isEmpty || saving) return;
    if (widget.row != null && builtIns.contains(widget.row?['name'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les listes prédéfinies RouterOS sont protégées.'),
        ),
      );
      return;
    }
    setState(() => saving = true);
    final v = {
      'name': n,
      'include': include.text.trim(),
      'exclude': exclude.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/interface/list', v);
      else
        await widget.service.set('/interface/list', id, v);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null
            ? 'Nouvelle Interface List'
            : 'Modifier Interface List',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          enabled:
              widget.row == null || !builtIns.contains(widget.row?['name']),
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: include,
          decoration: const InputDecoration(
            labelText: 'Include',
            hintText: 'LAN,WAN',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: exclude,
          decoration: const InputDecoration(
            labelText: 'Exclude',
            hintText: 'WAN',
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Ordre RouterOS : include → exclude → membres statiques. Les listes all, none, dynamic et static sont prédéfinies.',
            ),
          ),
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
    include.dispose();
    exclude.dispose();
    super.dispose();
  }
}
