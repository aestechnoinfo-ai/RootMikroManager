import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotServerScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotServerScreen({super.key, required this.service});
  @override
  State<HotspotServerScreen> createState() => _HotspotServerScreenState();
}

class _HotspotServerScreenState extends State<HotspotServerScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.hotspotServers();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? row]) async {
    final c = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.hotspotServerEdit,
      extra: OptionalRowPayload(row),
    );
    if (c == true) await load();
  }

  Future<void> toggle(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final off = r['disabled'] == 'yes' || r['disabled'] == 'true';
    if (off)
      await widget.service.enable('/ip/hotspot', id);
    else
      await widget.service.disable('/ip/hotspot', id);
    await load();
  }

  Future<void> remove(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    await widget.service.remove('/ip/hotspot', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Hotspot Servers'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter Hotspot Server'),
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
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      final off =
                          r['disabled'] == 'yes' || r['disabled'] == 'true';
                      return Card(
                        child: ListTile(
                          onTap: () => edit(r),
                          leading: Icon(
                            off
                                ? Icons.pause_circle_outline
                                : Icons.router_outlined,
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'Interface ${r['interface'] ?? '—'}',
                              'Pool ${r['address-pool'] ?? '—'}',
                              'Profile ${r['profile'] ?? '—'}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'toggle') toggle(r);
                              if (v == 'edit') edit(r);
                              if (v == 'delete') remove(r);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(off ? 'Activer' : 'Désactiver'),
                              ),
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
}
