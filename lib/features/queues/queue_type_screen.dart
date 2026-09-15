import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class QueueTypeScreen extends StatefulWidget {
  final RouterOsService service;
  const QueueTypeScreen({super.key, required this.service});

  @override
  State<QueueTypeScreen> createState() => _QueueTypeScreenState();
}

class _QueueTypeScreenState extends State<QueueTypeScreen> {
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
    rows = await widget.service.queueTypes();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> editor([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.queueTypeEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> remove(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    await widget.service.remove('/queue/type', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Queue Types'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Rechercher',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => editor(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter Queue Type'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final r = visible[i];
                      final builtin =
                          r['default'] == 'true' || r['default'] == 'yes';
                      return Card(
                        child: ListTile(
                          onTap: builtin ? null : () => editor(r),
                          leading: const CircleAvatar(child: Icon(Icons.tune)),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'Kind ${r['kind'] ?? '—'}',
                              if ((r['pcq-rate'] ?? '').isNotEmpty)
                                'Rate ${r['pcq-rate']}',
                              if ((r['pcq-classifier'] ?? '').isNotEmpty)
                                r['pcq-classifier']!,
                            ].join(' • '),
                          ),
                          trailing: builtin
                              ? const Text('Default')
                              : PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') editor(r);
                                    if (v == 'delete') remove(r);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Modifier'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Supprimer'),
                                    ),
                                  ],
                                ),
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
