import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';

class VrfScreen extends StatefulWidget {
  final RouterOsService service;
  const VrfScreen({super.key, required this.service});

  @override
  State<VrfScreen> createState() => _VrfScreenState();
}

class _VrfScreenState extends State<VrfScreen> {
  final search = TextEditingController();
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.ipVrfs();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('VRF (${rows.length})'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'VRF reste volontairement en lecture seule dans ce lot. '
                'Modifier l’ordre ou les interfaces d’un VRF peut déplacer '
                'des routes connectées et couper l’accès de management.',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Nom, interfaces, commentaire…',
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (_, index) {
                      final r = visible[index];
                      final name = r['name'] ?? '—';
                      final interfaces = r['interfaces'] ?? '—';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.account_tree_outlined),
                          title: Text(name),
                          subtitle: Text(
                            [
                              'interfaces: $interfaces',
                              if ((r['comment'] ?? '').isNotEmpty)
                                r['comment']!,
                            ].join(' • '),
                          ),
                          trailing: name == 'main'
                              ? const Chip(label: Text('main'))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
