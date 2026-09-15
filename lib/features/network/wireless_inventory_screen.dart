import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class WirelessInventoryScreen extends StatefulWidget {
  final RouterOsService service;
  const WirelessInventoryScreen({super.key, required this.service});

  @override
  State<WirelessInventoryScreen> createState() =>
      _WirelessInventoryScreenState();
}

class _WirelessInventoryScreenState extends State<WirelessInventoryScreen> {
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
    rows = await widget.service.wirelessInterfacesAll();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> toggle(Map<String, String> row) async {
    final id = row['.id'];
    final path = row['_path'];
    if (id == null || path == null) return;
    final disabled = row['disabled'] == 'yes' || row['disabled'] == 'true';
    if (disabled)
      await widget.service.enable(path, id);
    else
      await widget.service.disable(path, id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Interfaces Wi‑Fi (${rows.length})'),
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
              labelText: 'Nom, SSID, bande, fréquence…',
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
                      final disabled =
                          r['disabled'] == 'yes' || r['disabled'] == 'true';
                      return Card(
                        child: ListTile(
                          onTap: () => AppRouter.pushNamed(
                            context,
                            AppRoutes.wirelessDetail,
                            extra: RequiredRowPayload(r),
                          ),
                          leading: CircleAvatar(
                            child: Icon(disabled ? Icons.wifi_off : Icons.wifi),
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              r['_backend'] ?? '',
                              if ((r['ssid'] ?? r['configuration.ssid'] ?? '')
                                  .isNotEmpty)
                                'SSID ${r['ssid'] ?? r['configuration.ssid']}',
                              if ((r['band'] ?? '').isNotEmpty) r['band']!,
                              if ((r['frequency'] ?? '').isNotEmpty)
                                '${r['frequency']} MHz',
                            ].where((e) => e.isNotEmpty).join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'toggle') toggle(r);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  disabled ? 'Activer' : 'Désactiver',
                                ),
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
