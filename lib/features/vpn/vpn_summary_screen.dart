import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VpnSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const VpnSummaryScreen({super.key, required this.service});

  @override
  State<VpnSummaryScreen> createState() => _VpnSummaryScreenState();
}

class _VpnSummaryScreenState extends State<VpnSummaryScreen> {
  bool loading = true;
  int wgInterfaces = 0;
  int wgPeers = 0;
  int wgHandshakes = 0;
  int ztInterfaces = 0;
  int bthUsers = 0;
  String bthStatus = '—';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);

    final wg = await widget.service.wireGuardInterfaces();
    final peers = await widget.service.wireGuardPeers();

    var zt = <Map<String, String>>[];
    var bth = <Map<String, String>>[];
    var cloud = <String, String>{};

    try {
      zt = await widget.service.zeroTierInterfaces();
    } catch (_) {}
    try {
      bth = await widget.service.backToHomeUsers();
    } catch (_) {}
    try {
      cloud = await widget.service.backToHomeStatus();
    } catch (_) {}

    wgInterfaces = wg.length;
    wgPeers = peers.length;
    wgHandshakes = peers.where((e) {
      final h = (e['last-handshake'] ?? '').trim();
      return h.isNotEmpty && h != 'never' && h != '0s';
    }).length;
    ztInterfaces = zt.length;
    bthUsers = bth.length;
    bthStatus =
        cloud['vpn-status'] ?? cloud['back-to-home-vpn'] ?? 'Indisponible';

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé VPN'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _c(
                'Interfaces WireGuard',
                '$wgInterfaces',
                Icons.vpn_key_outlined,
              ),
              _c('Peers WireGuard', '$wgPeers', Icons.people_outline),
              _c(
                'Peers avec handshake',
                '$wgHandshakes',
                Icons.handshake_outlined,
              ),
              _c('Interfaces ZeroTier', '$ztInterfaces', Icons.hub_outlined),
              _c('Back to Home users', '$bthUsers', Icons.person_outline),
              _c('Back to Home status', bthStatus, Icons.home_work_outlined),
            ],
          ),
  );

  Widget _c(String title, String value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    ),
  );
}
