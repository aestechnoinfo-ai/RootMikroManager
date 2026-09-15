import 'package:flutter/material.dart';

import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class IpAddressesScreen extends StatefulWidget {
  final RouterOsService service;
  const IpAddressesScreen({super.key, required this.service});

  @override
  State<IpAddressesScreen> createState() => _IpAddressesScreenState();
}

class _IpAddressesScreenState extends State<IpAddressesScreen> {
  final search = TextEditingController();
  bool loading = true;
  String filter = 'all';
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  bool yes(Map<String, String> row, String key) =>
      row[key] == 'yes' || row[key] == 'true';

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      rows = await widget.service.ipAddresses();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((row) {
      final dynamic = yes(row, 'dynamic');
      if (filter == 'static' && dynamic) return false;
      if (filter == 'dynamic' && !dynamic) return false;
      if (q.isNotEmpty && !row.values.any((v) => v.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.ipAddressEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> remove(Map<String, String> row) async {
    if (yes(row, 'dynamic')) return;
    final id = row['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cette adresse IPv4 ?'),
            content: Text(
              '${row['address'] ?? '—'} sur ${row['interface'] ?? '—'}\n\n'
              'La suppression peut couper l’accès au routeur si cette adresse '
              'est utilisée pour l’administration.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await widget.service.remove('/ip/address', id);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final staticCount = rows.where((r) => !yes(r, 'dynamic')).length;
    final dynamicCount = rows.length - staticCount;
    return Scaffold(
      appBar: AppBar(
        title: Text('Adresses IPv4 (${rows.length})'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Adresse, interface, réseau, commentaire…',
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'all',
                        label: Text('Toutes ${rows.length}'),
                      ),
                      ButtonSegment(
                        value: 'static',
                        label: Text('Statiques $staticCount'),
                      ),
                      ButtonSegment(
                        value: 'dynamic',
                        label: Text('Dynamiques $dynamicCount'),
                      ),
                    ],
                    selected: {filter},
                    onSelectionChanged: (v) => setState(() => filter = v.first),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter adresse IPv4'),
                  ),
                ),
              ],
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
                        final dynamic = yes(row, 'dynamic');
                        final invalid = yes(row, 'invalid');
                        return Card(
                          child: ListTile(
                            onTap: dynamic ? null : () => edit(row),
                            leading: CircleAvatar(
                              child: Icon(
                                invalid
                                    ? Icons.error_outline
                                    : dynamic
                                    ? Icons.bolt
                                    : Icons.language_outlined,
                              ),
                            ),
                            title: Text(row['address'] ?? '—'),
                            subtitle: Text(
                              [
                                'Interface ${row['interface'] ?? '—'}',
                                if ((row['network'] ?? '').isNotEmpty)
                                  'Network ${row['network']}',
                                dynamic ? 'Dynamic' : 'Static',
                                if ((row['comment'] ?? '').isNotEmpty)
                                  row['comment']!,
                              ].join(' • '),
                            ),
                            trailing: dynamic
                                ? null
                                : PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') edit(row);
                                      if (v == 'delete') remove(row);
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
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
