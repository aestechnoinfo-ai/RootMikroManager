import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class QueueTypeEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const QueueTypeEditorScreen({super.key, required this.service, this.row});

  @override
  State<QueueTypeEditorScreen> createState() => _QueueTypeEditorScreenState();
}

class _QueueTypeEditorScreenState extends State<QueueTypeEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController pcqRate;
  late final TextEditingController pcqLimit;
  late final TextEditingController pcqTotalLimit;
  String kind = 'pcq';
  String classifier = 'dst-address';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    pcqRate = TextEditingController(text: r?['pcq-rate'] ?? '0');
    pcqLimit = TextEditingController(text: r?['pcq-limit'] ?? '50KiB');
    pcqTotalLimit = TextEditingController(
      text: r?['pcq-total-limit'] ?? '2000KiB',
    );
    kind = r?['kind'] ?? 'pcq';
    classifier = r?['pcq-classifier'] ?? 'dst-address';
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || saving) return;
    setState(() => saving = true);

    final values = <String, String>{
      'name': name.text.trim(),
      'kind': kind,
      if (kind == 'pcq') 'pcq-rate': pcqRate.text.trim(),
      if (kind == 'pcq') 'pcq-limit': pcqLimit.text.trim(),
      if (kind == 'pcq') 'pcq-total-limit': pcqTotalLimit.text.trim(),
      if (kind == 'pcq') 'pcq-classifier': classifier,
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/queue/type', values);
      } else {
        await widget.service.set('/queue/type', id, values);
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
        widget.row == null ? 'Ajouter Queue Type' : 'Modifier Queue Type',
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
        DropdownButtonFormField<String>(isExpanded: true, 
          value: kind,
          decoration: const InputDecoration(labelText: 'Kind'),
          items: const [
            'pcq',
            'pfifo',
            'bfifo',
            'red',
            'sfq',
            'mq-pfifo',
            'cake',
            'codel',
            'fq-codel',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => kind = v ?? 'pcq'),
        ),
        if (kind == 'pcq') ...[
          const SizedBox(height: 10),
          TextField(
            controller: pcqRate,
            decoration: const InputDecoration(
              labelText: 'PCQ Rate',
              hintText: '0 ou 10M',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
            value: classifier,
            decoration: const InputDecoration(labelText: 'PCQ Classifier'),
            items: const [
              'src-address',
              'dst-address',
              'src-port',
              'dst-port',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => classifier = v ?? classifier),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: pcqLimit,
            decoration: const InputDecoration(labelText: 'PCQ Limit'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: pcqTotalLimit,
            decoration: const InputDecoration(labelText: 'PCQ Total Limit'),
          ),
        ],
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
    pcqRate.dispose();
    pcqLimit.dispose();
    pcqTotalLimit.dispose();
    super.dispose();
  }
}
