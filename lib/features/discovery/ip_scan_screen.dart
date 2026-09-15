import 'package:flutter/material.dart';

import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/network/ip_scanner_service.dart';
import 'discovery_candidate.dart';
import 'discovery_settings.dart';
import '../../shared/widgets/mikrotik_router_image.dart';

class IpScanScreen extends StatefulWidget {
  const IpScanScreen({super.key});
  @override
  State<IpScanScreen> createState() => _IpScanScreenState();
}

class _IpScanScreenState extends State<IpScanScreen> {
  final cidr = TextEditingController(text: '192.168.88.0/24');
  final scanner = IpScannerService();
  DiscoverySettings settings = const DiscoverySettings();
  final List<ScannedHost> hosts = [];
  bool scanning = false;
  String? error;
  String? localIpv4;
  CancellationToken? token;

  @override
  void initState() {
    super.initState();
    scanner.networkBinding.wifiIpv4().then((address) {
      if (mounted) setState(() => localIpv4 = address);
    });
    DiscoverySettings.load().then((value) {
      if (mounted) setState(() => settings = value);
    });
  }

  Future<void> scanIp() async => _run(
    scanner.scanCidrStream(
      cidr.text.trim(),
      ports: settings.ports,
      timeout: Duration(milliseconds: settings.scanTimeoutMs.clamp(500, 1500)),
      maxConcurrency: settings.scanConcurrency,
      maxHosts: settings.maxHosts,
      retries: 1,
      cancellationToken: token = CancellationToken(),
    ),
  );

  Future<void> scanMndp() async => _run(
    scanner.discoverMndp(
      duration: const Duration(seconds: 15),
      cancellationToken: token = CancellationToken(),
    ),
  );

  Future<void> _run(Stream<ScannedHost> stream) async {
    if (scanning) return;
    setState(() {
      scanning = true;
      error = null;
      hosts.clear();
    });
    try {
      await for (final host in stream) {
        if (mounted) setState(() => hosts.add(host));
      }
    } on ScanCancelledException {
      error = null;
    } catch (exception) {
      error = '$exception';
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<void> saveHost(ScannedHost host) async {
    token?.cancel();
    await AppRouter.pushNamed(
      context,
      AppRoutes.discoveryCandidateSave,
      extra: DiscoveryCandidatePayload(
        DiscoveryCandidate(
          source: host.protocols.contains('MNDP') ? 'MNDP' : 'Scan IP',
          identity: host.identity,
          address: host.ip,
          macAddress: host.macAddress,
          board: host.boardName,
          openPorts: host.openPorts,
          useTls: host.useTls,
          protocols: host.protocols,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Découverte MikroTik')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: cidr,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Réseau CIDR',
            hintText: '192.168.88.0/24',
          ),
        ),
        const SizedBox(height: 8),
        if (localIpv4 != null) Text('IPv4 Wi-Fi de cet appareil : $localIpv4'),
        const Text(
          'Neighbor MNDP : recherche locale pendant 15 secondes. '
          'Le téléphone doit être sur le même réseau Wi-Fi que le routeur.',
        ),
        Text(
          'Ports ${settings.ports.join(', ')} • '
          'détection rapide 1,5s • 1 passe',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: scanning ? null : scanIp,
              icon: const Icon(Icons.radar),
              label: const Text('Scan IP / API'),
            ),
            FilledButton.tonalIcon(
              onPressed: scanning ? null : scanMndp,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Neighbor MNDP'),
            ),
            if (scanning)
              OutlinedButton.icon(
                onPressed: token?.cancel,
                icon: const Icon(Icons.stop),
                label: const Text('Arrêter'),
              ),
          ],
        ),
        if (scanning) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 16),
        Text(
          '${hosts.length} routeur(s), ordre d’arrivée',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final host in hosts)
          Card(
            child: ListTile(
              leading: _hardwareVisual(host),
              title: Text(host.identity.isEmpty ? host.ip : host.identity),
              subtitle: Text(
                [
                  if (host.ip.isNotEmpty) host.ip,
                  if (host.macAddress.isNotEmpty) host.macAddress,
                  if (host.boardName.isNotEmpty) host.boardName,
                  if (host.openPorts.isNotEmpty)
                    'Ports ${host.openPorts.join(', ')}',
                  ...host.protocols,
                ].join(' • '),
              ),
              trailing: host.likelyMikrotik
                  ? IconButton(
                      tooltip: 'Enregistrer comme routeur',
                      onPressed: () => saveHost(host),
                      icon: const Icon(Icons.bookmark_add_outlined),
                    )
                  : null,
              onTap: host.likelyMikrotik ? () => saveHost(host) : null,
            ),
          ),
      ],
    ),
  );

  Widget _hardwareVisual(ScannedHost host) {
    return MikrotikRouterImage(boardName: host.boardName, size: 52);
  }

  @override
  void dispose() {
    token?.cancel();
    cidr.dispose();
    super.dispose();
  }
}
