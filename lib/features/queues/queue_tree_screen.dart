import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class QueueTreeScreen extends StatefulWidget {
  final RouterOsService service;
  const QueueTreeScreen({super.key, required this.service});

  @override
  State<QueueTreeScreen> createState() => _QueueTreeScreenState();
}

class _QueueTreeScreenState extends State<QueueTreeScreen> {
  final search = TextEditingController();
  List<Map<String, String>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.queueTree();
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
      AppRoutes.queueTreeEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> action(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    if (action == 'edit') return editor(row);
    if (action == 'enable') {
      await widget.service.enable('/queue/tree', id);
    } else if (action == 'disable') {
      await widget.service.disable('/queue/tree', id);
    } else if (action == 'delete') {
      await widget.service.remove('/queue/tree', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Queue Tree')),
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
              label: const Text('Ajouter Queue Tree'),
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
                    itemBuilder: (_, i) {
                      final row = visible[i];
                      final disabled =
                          row['disabled'] == 'true' || row['disabled'] == 'yes';
                      return Card(
                        child: ListTile(
                          onTap: () => editor(row),
                          leading: CircleAvatar(
                            child: Icon(
                              disabled
                                  ? Icons.pause
                                  : Icons.account_tree_outlined,
                            ),
                          ),
                          title: Text(row['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'Parent: ${row['parent'] ?? '—'}',
                              if ((row['packet-mark'] ?? '').isNotEmpty)
                                'Mark: ${row['packet-mark']}',
                              'Max: ${row['max-limit'] ?? '—'}',
                              if ((row['rate'] ?? '').isNotEmpty)
                                'Rate: ${row['rate']}',
                              if ((row['bytes'] ?? '').isNotEmpty)
                                'Bytes: ${row['bytes']}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => action(v, row),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Modifier'),
                              ),
                              PopupMenuItem(
                                value: disabled ? 'enable' : 'disable',
                                child: Text(
                                  disabled ? 'Activer' : 'Désactiver',
                                ),
                              ),
                              const PopupMenuItem(
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
