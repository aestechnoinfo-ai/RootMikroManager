import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotServerProfileScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotServerProfileScreen({super.key, required this.service});
  @override
  State<HotspotServerProfileScreen> createState() =>
      _HotspotServerProfileScreenState();
}

class _HotspotServerProfileScreenState
    extends State<HotspotServerProfileScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.hotspotServerProfiles();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? r]) async {
    final c = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.hotspotServerProfileEdit,
      extra: OptionalRowPayload(r),
    );
    if (c == true) await load();
  }

  Future<void> remove(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    await widget.service.remove('/ip/hotspot/profile', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Hotspot Server Profiles'),
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
              label: const Text('Ajouter Server Profile'),
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
                      return Card(
                        child: ListTile(
                          onTap: () => edit(r),
                          leading: const CircleAvatar(
                            child: Icon(Icons.settings_ethernet_outlined),
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'DNS ${r['dns-name'] ?? '—'}',
                              'Login ${r['login-by'] ?? '—'}',
                              if ((r['rate-limit'] ?? '').isNotEmpty)
                                'Rate ${r['rate-limit']}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
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
}
