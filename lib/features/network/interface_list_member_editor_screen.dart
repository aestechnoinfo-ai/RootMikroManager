import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class InterfaceListMemberEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const InterfaceListMemberEditorScreen({
    super.key,
    required this.service,
    this.row,
  });
  @override
  State<InterfaceListMemberEditorScreen> createState() => _State();
}

class _State extends State<InterfaceListMemberEditorScreen> {
  String list = '', interface = '';
  bool loading = true, saving = false;
  List<String> lists = [], interfaces = [];

  @override
  void initState() {
    super.initState();
    list = widget.row?['list'] ?? '';
    interface = widget.row?['interface'] ?? '';
    load();
  }

  Future<void> load() async {
    final r = await Future.wait([
      widget.service.interfaceLists(),
      widget.service.interfaces(),
    ]);
    lists =
        r[0]
            .map((e) => e['name'] ?? '')
            .where(
              (e) =>
                  e.isNotEmpty &&
                  e != 'all' &&
                  e != 'none' &&
                  e != 'dynamic' &&
                  e != 'static',
            )
            .toList()
          ..sort();
    interfaces =
        r[1].map((e) => e['name'] ?? '').where((e) => e.isNotEmpty).toList()
          ..sort();
    if (list.isNotEmpty && !lists.contains(list)) lists.add(list);
    if (interface.isNotEmpty && !interfaces.contains(interface))
      interfaces.add(interface);
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (list.isEmpty || interface.isEmpty || saving) return;
    setState(() => saving = true);
    final v = {'list': list, 'interface': interface};
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/interface/list/member', v);
      else
        await widget.service.set('/interface/list/member', id, v);
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
        widget.row == null ? 'Ajouter un membre' : 'Modifier un membre',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                value: list.isEmpty ? null : list,
                decoration: const InputDecoration(labelText: 'Interface List'),
                items: lists
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => list = v ?? ''),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: interface.isEmpty ? null : interface,
                decoration: const InputDecoration(labelText: 'Interface'),
                items: interfaces
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => interface = v ?? ''),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Ajouter un bridge à une liste n’ajoute pas automatiquement tous ses ports.',
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
}
