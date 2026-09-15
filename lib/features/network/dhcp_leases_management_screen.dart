import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class DhcpLeasesManagementScreen extends StatefulWidget {
  final RouterOsService service;
  const DhcpLeasesManagementScreen({super.key, required this.service});

  @override
  State<DhcpLeasesManagementScreen> createState() =>
      _DhcpLeasesManagementScreenState();
}

class _DhcpLeasesManagementScreenState
    extends State<DhcpLeasesManagementScreen> {
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

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.dhcpLeases();
    if (mounted) setState(() => loading = false);
  }

  bool isDynamic(Map<String, String> r) =>
      r['dynamic'] == 'yes' || r['dynamic'] == 'true';

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) {
      final dynamic = isDynamic(r);
      if (filter == 'static' && dynamic) return false;
      if (filter == 'dynamic' && !dynamic) return false;
      if (q.isNotEmpty && !r.values.any((v) => v.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.dhcpLeaseEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> makeStatic(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    await widget.service.makeDhcpLeaseStatic(id);
    await load();
  }

  Future<void> remove(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null || isDynamic(row)) return;
    final label =
        row['host-name'] ?? row['address'] ?? row['mac-address'] ?? id;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer le bail statique ?'),
            content: Text(
              'Le bail « $label » sera retiré du serveur DHCP. '
              'Le client pourra ensuite obtenir un nouveau bail dynamique.',
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
    await widget.service.remove('/ip/dhcp-server/lease', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Baux DHCP'),
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
              labelText: 'IP, MAC, host, serveur…',
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
              label: const Text('Ajouter bail statique'),
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
                      final dynamic = isDynamic(r);
                      return Card(
                        child: ListTile(
                          onTap: dynamic ? null : () => edit(r),
                          leading: CircleAvatar(
                            child: Text(dynamic ? 'D' : 'S'),
                          ),
                          title: Text(r['address'] ?? '—'),
                          subtitle: Text(
                            [
                              'MAC ${r['mac-address'] ?? '—'}',
                              if ((r['host-name'] ?? '').isNotEmpty)
                                'Host ${r['host-name']}',
                              'Status ${r['status'] ?? '—'}',
                              if ((r['server'] ?? '').isNotEmpty)
                                'Server ${r['server']}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'static') makeStatic(r);
                              if (v == 'edit') edit(r);
                              if (v == 'delete') remove(r);
                            },
                            itemBuilder: (_) => [
                              if (dynamic)
                                const PopupMenuItem(
                                  value: 'static',
                                  child: Text('Rendre statique'),
                                ),
                              if (!dynamic)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
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
