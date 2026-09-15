import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'discovery_candidate.dart';

class RomonDiscoveryScreen extends StatefulWidget {
  final RouterOsService service;
  const RomonDiscoveryScreen({super.key, required this.service});

  @override
  State<RomonDiscoveryScreen> createState() => _RomonDiscoveryScreenState();
}

class _RomonDiscoveryScreenState extends State<RomonDiscoveryScreen> {
  bool loading = true;
  Map<String, String> status = {};
  List<Map<String, String>> ports = [];
  List<Map<String, String>> peers = [];
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      status = await widget.service.romonStatus();
      ports = await widget.service.romonPorts();
      peers = await widget.service.romonDiscover();
      final neighbors = await widget.service.neighbors();
      peers = peers.map((peer) {
        final romonMac = (peer['address'] ?? '').toLowerCase();
        final neighbor = neighbors.cast<Map<String, String>?>().firstWhere(
          (row) => (row?['mac-address'] ?? '').toLowerCase() == romonMac,
          orElse: () => null,
        );
        return {
          ...peer,
          if ((neighbor?['address'] ?? '').isNotEmpty)
            '_ip-address': neighbor!['address']!,
        };
      }).toList();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> toggle(bool enabled) async {
    await widget.service.setRomonEnabled(enabled);
    await load();
  }

  Future<void> savePeer(Map<String, String> row) async {
    final candidate = DiscoveryCandidate(
      source: 'RoMON',
      identity: row['identity'] ?? '',
      address: row['_ip-address'] ?? '',
      macAddress: row['address'] ?? '',
      romonId: row['address'] ?? '',
      protocols: const ['RoMON'],
      board: row['board'] ?? '',
      version: row['version'] ?? '',
      hops: int.tryParse(row['hops'] ?? ''),
      cost: int.tryParse(row['cost'] ?? ''),
    );
    await AppRouter.pushNamed(
      context,
      AppRoutes.discoveryCandidateSave,
      extra: DiscoveryCandidatePayload(candidate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = status['enabled'] == 'true' || status['enabled'] == 'yes';

    return Scaffold(
      appBar: AppBar(
        title: const Text('RoMON'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: SwitchListTile(
                    title: const Text('RoMON activé'),
                    subtitle: const Text(
                      'La découverte RoMON est exécutée depuis le '
                      'MikroTik connecté, pas directement par le téléphone.',
                    ),
                    value: enabled,
                    onChanged: toggle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${peers.length} pair(s) RoMON',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final row in peers)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.hub_outlined),
                      title: Text(
                        row['identity'] ?? row['address'] ?? 'Routeur RoMON',
                      ),
                      subtitle: Text(
                        [
                          if ((row['address'] ?? '').isNotEmpty)
                            'MAC ${row['address']}',
                          if ((row['_ip-address'] ?? '').isNotEmpty)
                            'IP ${row['_ip-address']}',
                          if ((row['hops'] ?? '').isNotEmpty)
                            'Hops ${row['hops']}',
                          if ((row['cost'] ?? '').isNotEmpty)
                            'Cost ${row['cost']}',
                          if ((row['board'] ?? '').isNotEmpty) row['board']!,
                          if ((row['version'] ?? '').isNotEmpty)
                            'ROS ${row['version']}',
                        ].join(' • '),
                      ),
                      trailing: (row['_ip-address'] ?? '').isEmpty
                          ? const Tooltip(
                              message: 'Aucune adresse IP associée',
                              child: Icon(Icons.info_outline),
                            )
                          : const Icon(Icons.bookmark_add_outlined),
                      onTap: (row['_ip-address'] ?? '').isEmpty
                          ? null
                          : () => savePeer(row),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Ports RoMON',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final row in ports)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.settings_ethernet),
                      title: Text(row['interface'] ?? 'Port'),
                      subtitle: Text(
                        [
                          if ((row['forbid'] ?? '').isNotEmpty)
                            'Forbid ${row['forbid']}',
                          if ((row['cost'] ?? '').isNotEmpty)
                            'Cost ${row['cost']}',
                          if ((row['secrets'] ?? '').isNotEmpty)
                            'Secrets configurés',
                        ].join(' • '),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
