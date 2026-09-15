import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class ArpScreen extends StatefulWidget {
  final RouterOsService service;
  const ArpScreen({super.key, required this.service});

  @override
  State<ArpScreen> createState() => _ArpScreenState();
}

class _ArpScreenState extends State<ArpScreen> {
  final search = TextEditingController();
  String filter = 'all';
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  bool yes(Map<String, String> r, String k) => r[k] == 'yes' || r[k] == 'true';

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.arpEntries();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) {
      final dynamic = yes(r, 'dynamic');
      if (filter == 'static' && dynamic) return false;
      if (filter == 'dynamic' && !dynamic) return false;
      if (filter == 'failed' && (r['status'] ?? '') != 'failed') return false;
      if (q.isNotEmpty && !r.values.any((v) => v.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> edit([Map<String, String>? r]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.networkArpEdit,
      extra: OptionalRowPayload(r),
    );
    if (changed == true) await load();
  }

  Future<void> remove(Map<String, String> r) async {
    if (yes(r, 'dynamic')) return;
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cette entrée ARP statique ?'),
            content: Text(
              '${r['address'] ?? '—'} → ${r['mac-address'] ?? '—'} sur ${r['interface'] ?? '—'}',
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
    await widget.service.remove('/ip/arp', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('ARP (${rows.length})'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    'Statiques ${rows.where((r) => !yes(r, 'dynamic')).length}',
                  ),
                  Text(
                    'Dynamiques ${rows.where((r) => yes(r, 'dynamic')).length}',
                  ),
                  Text(
                    'Failed ${rows.where((r) => (r['status'] ?? '') == 'failed').length}',
                  ),
                ],
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
              labelText: 'IP, MAC, interface, status…',
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('Tous')),
              ButtonSegment(value: 'static', label: Text('Statiques')),
              ButtonSegment(value: 'dynamic', label: Text('Dynamiques')),
              ButtonSegment(value: 'failed', label: Text('Failed')),
            ],
            selected: {filter},
            onSelectionChanged: (v) => setState(() => filter = v.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter ARP statique'),
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
                      final r = visible[i];
                      final dynamic = yes(r, 'dynamic');
                      return Card(
                        child: ListTile(
                          onTap: dynamic ? null : () => edit(r),
                          leading: CircleAvatar(
                            child: Icon(
                              dynamic ? Icons.bolt : Icons.link_outlined,
                            ),
                          ),
                          title: Text(r['address'] ?? '—'),
                          subtitle: Text(
                            [
                              'MAC ${r['mac-address'] ?? '—'}',
                              'Interface ${r['interface'] ?? '—'}',
                              if ((r['status'] ?? '').isNotEmpty)
                                'Status ${r['status']}',
                              if (yes(r, 'published')) 'Published',
                            ].join(' • '),
                          ),
                          trailing: dynamic
                              ? null
                              : PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') edit(r);
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
