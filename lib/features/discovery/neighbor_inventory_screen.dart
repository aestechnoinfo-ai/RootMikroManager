import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'discovery_candidate.dart';

class NeighborInventoryScreen extends StatefulWidget {
  final RouterOsService service;
  const NeighborInventoryScreen({super.key, required this.service});

  @override
  State<NeighborInventoryScreen> createState() =>
      _NeighborInventoryScreenState();
}

class _NeighborInventoryScreenState extends State<NeighborInventoryScreen> {
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
    rows = await widget.service.neighbors();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> saveRouter(Map<String, String> row) async {
    final candidate = DiscoveryCandidate(
      source: 'Neighbor',
      identity: row['identity'] ?? '',
      address: row['address'] ?? '',
      macAddress: row['mac-address'] ?? '',
      board: row['board'] ?? '',
      version: row['version'] ?? '',
      interfaceName: row['interface'] ?? '',
      protocols: (row['discovered-by'] ?? 'MNDP')
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
    );
    await AppRouter.pushNamed(
      context,
      AppRoutes.discoveryCandidateSave,
      extra: DiscoveryCandidatePayload(candidate),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Neighbors'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Cette liste provient du MikroTik connecté. Elle reflète '
                'MNDP/CDP/LLDP visibles dans son domaine Layer 2.',
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
              labelText: 'Identity, IP, MAC, board, interface…',
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
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.router_outlined),
                          title: Text(
                            row['identity'] ??
                                row['address'] ??
                                row['mac-address'] ??
                                '—',
                          ),
                          subtitle: Text(
                            [
                              if ((row['address'] ?? '').isNotEmpty)
                                'IP ${row['address']}',
                              if ((row['mac-address'] ?? '').isNotEmpty)
                                'MAC ${row['mac-address']}',
                              if ((row['interface'] ?? '').isNotEmpty)
                                'IF ${row['interface']}',
                              if ((row['board'] ?? '').isNotEmpty)
                                row['board']!,
                              if ((row['version'] ?? '').isNotEmpty)
                                'ROS ${row['version']}',
                              if ((row['discovered-by'] ?? '').isNotEmpty)
                                'Via ${row['discovered-by']}',
                            ].join(' • '),
                          ),
                          trailing: (row['address'] ?? '').isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Enregistrer comme routeur',
                                  onPressed: () => saveRouter(row),
                                  icon: const Icon(Icons.bookmark_add_outlined),
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
