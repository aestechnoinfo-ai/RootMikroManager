import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class IpPoolScreen extends StatefulWidget {
  final RouterOsService service;
  const IpPoolScreen({super.key, required this.service});
  @override
  State<IpPoolScreen> createState() => _IpPoolScreenState();
}

class _IpPoolScreenState extends State<IpPoolScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.ipPools();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.hotspotIpPoolEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> remove(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    await widget.service.remove('/ip/pool', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('IP Pools'),
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
              label: const Text('Ajouter IP Pool'),
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
                          leading: const CircleAvatar(
                            child: Icon(Icons.hub_outlined),
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'Ranges ${r['ranges'] ?? '—'}',
                              if ((r['next-pool'] ?? 'none') != 'none')
                                'Next ${r['next-pool']}',
                            ].join(' • '),
                          ),
                          onTap: () => edit(r),
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
