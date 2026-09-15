import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class IpPoolEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const IpPoolEditorScreen({super.key, required this.service, this.row});

  @override
  State<IpPoolEditorScreen> createState() => _IpPoolEditorScreenState();
}

class _IpPoolEditorScreenState extends State<IpPoolEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController ranges;
  String nextPool = 'none';
  List<String> pools = ['none'];
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.row?['name'] ?? '');
    ranges = TextEditingController(text: widget.row?['ranges'] ?? '');
    nextPool = widget.row?['next-pool'] ?? 'none';
    loadPools();
  }

  Future<void> loadPools() async {
    final rows = await widget.service.ipPools();
    final names = rows
        .map((e) => e['name'] ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    pools = ['none', ...names.where((e) => e != name.text)];
    if (!pools.contains(nextPool)) pools.add(nextPool);
    if (mounted) setState(() {});
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || ranges.text.trim().isEmpty || saving)
      return;
    setState(() => saving = true);
    try {
      final values = {
        'name': name.text.trim(),
        'ranges': ranges.text.trim(),
        'next-pool': nextPool,
      };
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ip/pool', values);
      } else {
        await widget.service.set('/ip/pool', id, values);
      }
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.row == null ? 'Ajouter IP Pool' : 'Modifier IP Pool'),
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
          controller: ranges,
          decoration: const InputDecoration(
            labelText: 'Plage(s) d’adresses',
            hintText: '192.168.10.2-192.168.10.254',
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: pools.contains(nextPool) ? nextPool : 'none',
          decoration: const InputDecoration(labelText: 'Next Pool'),
          items: pools
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => nextPool = v ?? 'none'),
        ),
        const SizedBox(height: 16),
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
    ranges.dispose();
    super.dispose();
  }
}
