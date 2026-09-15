import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VpnIntegrationSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const VpnIntegrationSummaryScreen({super.key, required this.service});
  @override
  State<VpnIntegrationSummaryScreen> createState() => _State();
}

class _State extends State<VpnIntegrationSummaryScreen> {
  bool loading = true;
  List<Map<String, String>> wg = [], wp = [], zt = [], neighbors = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await Future.wait([
      widget.service.wireGuardInterfaces(),
      widget.service.wireGuardPeers(),
      widget.service.zeroTierInterfaces(),
      widget.service.neighbors(),
    ]);
    wg = x[0];
    wp = x[1];
    zt = x[2];
    neighbors = x[3];
    if (mounted) setState(() => loading = false);
  }

  Widget k(String t, int n, IconData i) => Card(
    child: ListTile(leading: Icon(i), title: Text(t), trailing: Text('$n')),
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé VPN & Neighboring'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              k('WireGuard interfaces', wg.length, Icons.vpn_key_outlined),
              k('WireGuard peers', wp.length, Icons.people_outline),
              k('ZeroTier interfaces', zt.length, Icons.hub_outlined),
              k(
                'Neighbors vus par RouterOS',
                neighbors.length,
                Icons.router_outlined,
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Le VPN étend la portée IP de RootMikroManager, mais Neighbor Discovery reste dépendant du domaine L2 du routeur interrogé.',
                  ),
                ),
              ),
            ],
          ),
  );
}
