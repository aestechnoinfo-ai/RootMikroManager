import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VpnNeighborCandidatesScreen extends StatefulWidget {
  final RouterOsService service;
  const VpnNeighborCandidatesScreen({super.key, required this.service});

  @override
  State<VpnNeighborCandidatesScreen> createState() =>
      _VpnNeighborCandidatesScreenState();
}

class _VpnNeighborCandidatesScreenState
    extends State<VpnNeighborCandidatesScreen> {
  bool loading = true;
  List<Map<String, String>> neighbors = [];
  List<String> candidates = [];
  List<String> zeroTierNetworks = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.wireGuardPeers(),
      widget.service.zeroTierInterfaces(),
      widget.service.ipAddresses(),
      widget.service.neighbors(),
      widget.service.backToHomeUsers(),
    ]);

    final wireGuardPeers = x[0];
    final zeroTier = x[1];
    final addresses = x[2];
    neighbors = x[3];
    final bthUsers = x[4];

    final c = <String>{};
    for (final peer in wireGuardPeers) {
      for (final raw in (peer['allowed-address'] ?? '').split(',')) {
        final value = raw.trim();
        if (value.isNotEmpty) c.add(value);
      }
      final endpoint =
          peer['current-endpoint-address'] ?? peer['endpoint-address'] ?? '';
      if (endpoint.isNotEmpty) c.add('$endpoint/32');
    }

    final vpnInterfaces = <String>{
      ...zeroTier.map((e) => e['name'] ?? '').where((e) => e.isNotEmpty),
    };
    for (final address in addresses) {
      final iface = address['interface'] ?? '';
      if (vpnInterfaces.contains(iface) ||
          iface.toLowerCase().contains('wireguard') ||
          iface.toLowerCase().contains('back-to-home') ||
          iface.toLowerCase().contains('bth')) {
        final value = address['address'] ?? '';
        if (value.isNotEmpty) c.add(value);
      }
    }

    for (final user in bthUsers) {
      final value = user['client-address'] ?? '';
      if (value.isNotEmpty) c.add(value);
    }

    zeroTierNetworks =
        zeroTier
            .map((e) => e['network'] ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    candidates = c.toList()..sort();

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Neighboring via VPN'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'MNDP/CDP/LLDP restent des mécanismes L2. '
                    'WireGuard, Back To Home et la plupart des usages '
                    'ZeroTier sont donc traités ici comme des chemins IP '
                    'routés. RootMikroManager sonde des adresses/CIDR '
                    'joignables au lieu de prétendre qu’un broadcast L2 '
                    'traverse le tunnel.',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Neighbors vus par RouterOS'),
                  trailing: Text('${neighbors.length}'),
                ),
              ),
              for (final n in neighbors)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.router_outlined),
                    title: Text(n['identity'] ?? n['address'] ?? '—'),
                    subtitle: Text(
                      '${n['address'] ?? '—'} • '
                      '${n['interface'] ?? '—'} • '
                      '${n['discovered-by'] ?? '—'}',
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text('Candidats IP via VPN'),
              for (final value in candidates)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.vpn_lock_outlined),
                    title: Text(value),
                  ),
                ),
              if (candidates.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('Aucun candidat IP VPN détecté.'),
                  ),
                ),
              if (zeroTierNetworks.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Réseaux ZeroTier détectés'),
                for (final id in zeroTierNetworks)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.hub_outlined),
                      title: Text(id),
                      subtitle: const Text(
                        'Network ID uniquement — ce n’est pas une adresse '
                        'IP et il n’est pas utilisé directement comme cible '
                        'de scan.',
                      ),
                    ),
                  ),
              ],
            ],
          ),
  );
}
