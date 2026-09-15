import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class IpRoutesScreen extends StatefulWidget {
  final RouterOsService service;
  const IpRoutesScreen({super.key, required this.service});

  @override
  State<IpRoutesScreen> createState() => _IpRoutesScreenState();
}

class _IpRoutesScreenState extends State<IpRoutesScreen> {
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
    rows = await widget.service.ipRoutes();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) {
      final dynamic = yes(r, 'dynamic');
      if (filter == 'static' && dynamic) return false;
      if (filter == 'dynamic' && !dynamic) return false;
      if (filter == 'active' && !yes(r, 'active')) return false;
      if (filter == 'inactive' && yes(r, 'active')) return false;
      if (filter == 'disabled' && !yes(r, 'disabled')) return false;
      if (q.isNotEmpty && !r.values.any((v) => v.toLowerCase().contains(q)))
        return false;
      return true;
    }).toList();
  }

  Future<void> edit([Map<String, String>? r]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.ipRouteEdit,
      extra: OptionalRowPayload(r),
    );
    if (changed == true) await load();
  }

  Future<void> action(String a, Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final dynamic = yes(r, 'dynamic');
    if (a == 'detail') {
      await AppRouter.pushNamed(
        context,
        AppRoutes.ipRouteDetail,
        extra: RequiredRowPayload(r),
      );
      return;
    }
    if (dynamic) return;
    if (a == 'edit') return edit(r);
    if (a == 'toggle') {
      if (yes(r, 'disabled'))
        await widget.service.enable('/ip/route', id);
      else
        await widget.service.disable('/ip/route', id);
    } else if (a == 'delete') {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Supprimer cette route statique ?'),
              content: Text(
                '${r['dst-address'] ?? '0.0.0.0/0'} via ${r['gateway'] ?? '—'}\n\nUne mauvaise suppression peut couper la connectivité distante.',
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
      await widget.service.remove('/ip/route', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Routes IPv4 (${rows.length})'),
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
                  Text('Actives ${rows.where((r) => yes(r, 'active')).length}'),
                  Text(
                    'HW offload ${rows.where((r) => yes(r, 'hw-offloaded')).length}',
                  ),
                  Text(
                    'ECMP ${rows.where((r) => (r['gateway'] ?? '').contains(',')).length}',
                  ),
                  Text(
                    'Tables ${rows.map((r) => r['routing-table'] ?? 'main').toSet().length}',
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
              labelText: 'Destination, gateway, table, commentaire…',
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('Toutes')),
              ButtonSegment(value: 'static', label: Text('Statiques')),
              ButtonSegment(value: 'dynamic', label: Text('Dynamiques')),
              ButtonSegment(value: 'active', label: Text('Actives')),
              ButtonSegment(value: 'inactive', label: Text('Inactives')),
              ButtonSegment(value: 'disabled', label: Text('Désactivées')),
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
              label: const Text('Ajouter route statique'),
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
                      final active = yes(r, 'active');
                      final disabled = yes(r, 'disabled');
                      return Card(
                        child: ListTile(
                          onTap: () => action('detail', r),
                          leading: CircleAvatar(
                            child: Icon(
                              disabled
                                  ? Icons.pause
                                  : active
                                  ? Icons.alt_route
                                  : Icons.route_outlined,
                            ),
                          ),
                          title: Text(r['dst-address'] ?? '0.0.0.0/0'),
                          subtitle: Text(
                            [
                              'GW ${r['gateway'] ?? '—'}',
                              'Distance ${r['distance'] ?? '—'}',
                              if ((r['routing-table'] ?? '').isNotEmpty)
                                'Table ${r['routing-table']}',
                              dynamic ? 'Dynamic' : 'Static',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => action(v, r),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'detail',
                                child: Text('Détails'),
                              ),
                              if (!dynamic)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                              if (!dynamic)
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(
                                    disabled ? 'Activer' : 'Désactiver',
                                  ),
                                ),
                              if (!dynamic)
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
