import 'package:flutter/material.dart';
import 'network_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class RoutingTableEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const RoutingTableEditorScreen({super.key, required this.service, this.row});
  @override
  State<RoutingTableEditorScreen> createState() => _S();
}

class _S extends State<RoutingTableEditorScreen> {
  late final TextEditingController name, comment;
  bool fib = true, saving = false;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.row?['name'] ?? '');
    comment = TextEditingController(text: widget.row?['comment'] ?? '');
    fib = widget.row?['fib'] != 'no';
  }

  Future<void> save() async {
    if (saving) return;
    if (widget.row?['name'] == 'main') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La table main est protégée.')),
      );
      return;
    }
    final error = NetworkInputValidator.interfaceName(name.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => saving = true);
    try {
      final v = {
        'name': name.text.trim(),
        'fib': fib ? 'yes' : 'no',
        'comment': comment.text.trim(),
      };
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/routing/table', v);
      else
        await widget.service.set('/routing/table', id, v);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null
            ? 'Nouvelle table de routage'
            : 'Modifier table de routage',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          enabled: widget.row?['name'] != 'main',
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: comment,
          decoration: const InputDecoration(labelText: 'Commentaire'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('FIB'),
          value: fib,
          onChanged: (v) => setState(() => fib = v),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'La table main est protégée. Une table personnalisée doit exister avant d’être référencée.',
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
    comment.dispose();
    super.dispose();
  }
}
