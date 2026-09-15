import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemScriptEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const SystemScriptEditorScreen({super.key, required this.service, this.row});
  @override
  State<SystemScriptEditorScreen> createState() => _State();
}

class _State extends State<SystemScriptEditorScreen> {
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
  late final TextEditingController name, source, comment;
  final selected = <String>{};
  bool dontRequire = false, saving = false;
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    source = TextEditingController(text: r?['source'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    dontRequire =
        r?['dont-require-permissions'] == 'yes' ||
        r?['dont-require-permissions'] == 'true';
    selected.addAll(
      (r?['policy'] ?? '')
          .split(',')
          .map((e) => e.trim())
          .where(policies.contains),
    );
  }

  bool get risky =>
      selected.contains('password') ||
      selected.contains('policy') ||
      selected.contains('sensitive') ||
      selected.contains('reboot') ||
      selected.contains('sniff') ||
      dontRequire;
  Future<void> save() async {
    if (!(key.currentState?.validate() ?? false) || saving) return;
    final duplicate = await widget.service.scriptNameExists(
      name.text.trim(),
      exceptId: widget.row?['.id'],
    );
    if (duplicate) {
      note('Un script porte déjà ce nom.');
      return;
    }
    setState(() => saving = true);
    final v = {
      'name': name.text.trim(),
      'source': source.text,
      'policy': selected.join(','),
      'dont-require-permissions': dontRequire ? 'yes' : 'no',
      'comment': comment.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/system/script', v);
      else
        await widget.service.set('/system/script', id, v);
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
      title: Text(widget.row == null ? 'Nouveau script' : 'Modifier script'),
    ),
    body: Form(
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
          TextFormField(
            controller: source,
            minLines: 10,
            maxLines: 28,
            decoration: const InputDecoration(
              labelText: 'Source *',
              alignLabelWithHint: true,
              hintText: ':log info "hello"',
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Source obligatoire' : null,
          ),
          const SizedBox(height: 12),
          Text('Policies', style: Theme.of(c).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in policies)
                FilterChip(
                  label: Text(p),
                  selected: selected.contains(p),
                  onSelected: (v) =>
                      setState(() => v ? selected.add(p) : selected.remove(p)),
                ),
            ],
          ),
          if (risky)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Ce script possède des permissions sensibles ou contourne une partie du contrôle de permissions. Gardez uniquement les droits nécessaires.',
                ),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: comment,
            decoration: const InputDecoration(labelText: 'Commentaire'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dont Require Permissions'),
            subtitle: const Text(
              'À utiliser uniquement pour un besoin précis : cette option réduit les contrôles de permissions de certains contextes d’exécution.',
            ),
            value: dontRequire,
            onChanged: (v) => setState(() => dontRequire = v),
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
    source.dispose();
    comment.dispose();
    super.dispose();
  }
}
