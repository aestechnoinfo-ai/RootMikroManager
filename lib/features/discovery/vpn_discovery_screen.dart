import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';

import '../../core/network/ip_scanner_service.dart';
import '../../core/network/vpn_discovery_service.dart';
import '../../core/routeros/routeros_service.dart';
import 'discovery_candidate.dart';
import 'discovery_settings.dart';

class VpnDiscoveryScreen extends StatefulWidget {
  final RouterOsService service;
  const VpnDiscoveryScreen({super.key, required this.service});

  @override
  State<VpnDiscoveryScreen> createState() => _VpnDiscoveryScreenState();
}

class _VpnDiscoveryScreenState extends State<VpnDiscoveryScreen> {
  late final VpnDiscoveryService discovery;
  DiscoverySettings settings = const DiscoverySettings();
  VpnDiscoveryResult? result;
  final Map<String, List<ScannedHost>> scans = {};
  final Set<String> scanning = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    discovery = VpnDiscoveryService(
      routerOs: widget.service,
      scanner: IpScannerService(),
    );
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    settings = await DiscoverySettings.load();
    result = await discovery.inspectRouterVpns();
    if (mounted) setState(() => loading = false);
  }

  Future<void> scan(VpnCandidateNetwork network) async {
    if (scanning.contains(network.cidr)) return;
    setState(() => scanning.add(network.cidr));

    try {
      final hosts = await discovery.scanner.scanCidr(
        network.cidr,
        ports: settings.ports,
        timeout: Duration(milliseconds: settings.scanTimeoutMs),
        maxConcurrency: settings.scanConcurrency,
        maxHosts: settings.maxHosts,
      );
      if (mounted) setState(() => scans[network.cidr] = hosts);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => scanning.remove(network.cidr));
    }
  }

  Future<void> manualScan() async {
    final controller = TextEditingController();
    final cidr = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scanner un CIDR'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'CIDR',
            hintText: '10.10.10.0/24',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Scanner'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (cidr == null || cidr.isEmpty) return;
    await scan(
      VpnCandidateNetwork(source: 'Scan manuel', name: cidr, cidr: cidr),
    );
  }

  Future<void> saveHost(ScannedHost host, String source) async {
    await AppRouter.pushNamed(
      context,
      AppRoutes.discoveryCandidateSave,
      extra: DiscoveryCandidatePayload(
        DiscoveryCandidate(
          source: source,
          address: host.ip,
          openPorts: host.openPorts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Découverte VPN'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VPN-aware',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'WireGuard et BackToHome sont scannés comme '
                          'réseaux IP routés. ZeroTier est également scanné '
                          'par IP pour rester fiable sur Android/iOS.',
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: manualScan,
                          icon: const Icon(Icons.radar),
                          label: const Text('Scanner un CIDR manuel'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (data != null && data.backToHome.isNotEmpty)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: const Text('BackToHome'),
                      subtitle: Text(
                        [
                          if ((data.backToHome['vpn-status'] ?? '').isNotEmpty)
                            'Statut ${data.backToHome['vpn-status']}',
                          if ((data.backToHome['vpn-dns-name'] ?? '')
                              .isNotEmpty)
                            data.backToHome['vpn-dns-name']!,
                          if ((data.backToHome['vpn-port'] ?? '').isNotEmpty)
                            'Port ${data.backToHome['vpn-port']}',
                        ].join(' • '),
                      ),
                    ),
                  ),
                if (data != null)
                  for (final network in data.networks) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.vpn_lock_outlined),
                            title: Text(network.name),
                            subtitle: Text(
                              '${network.source} • ${network.cidr}',
                            ),
                            trailing: FilledButton.tonal(
                              onPressed: scanning.contains(network.cidr)
                                  ? null
                                  : () => scan(network),
                              child: Text(
                                scanning.contains(network.cidr)
                                    ? 'Scan…'
                                    : 'Scanner',
                              ),
                            ),
                          ),
                          if (scans.containsKey(network.cidr))
                            for (final host in scans[network.cidr]!)
                              ListTile(
                                leading: Icon(
                                  host.likelyMikrotik
                                      ? Icons.router_outlined
                                      : Icons.devices_other,
                                ),
                                title: Text(host.ip),
                                subtitle: Text(
                                  'Ports ${host.openPorts.join(', ')}',
                                ),
                                trailing: host.likelyMikrotik
                                    ? IconButton(
                                        tooltip: 'Enregistrer',
                                        onPressed: () =>
                                            saveHost(host, network.source),
                                        icon: const Icon(
                                          Icons.bookmark_add_outlined,
                                        ),
                                      )
                                    : null,
                              ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
    );
  }
}
