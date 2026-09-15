import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VpnAdvancedSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const VpnAdvancedSummaryScreen({super.key, required this.service});

  @override
  State<VpnAdvancedSummaryScreen> createState() =>
      _VpnAdvancedSummaryScreenState();
}

class _VpnAdvancedSummaryScreenState extends State<VpnAdvancedSummaryScreen> {
  bool loading = true;
  Map<String, List<Map<String, String>>> inventory = {};
  String backToHome = '—';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    inventory = await widget.service.vpnProtocolInventory();
    final cloud = await widget.service.ipCloudStatus();
    backToHome =
        cloud['vpn-status'] ?? cloud['back-to-home-vpn'] ?? 'indisponible';
    if (mounted) setState(() => loading = false);
  }

  Widget countCard(String title, int count) => Card(
    child: ListTile(title: Text(title), trailing: Text('$count')),
  );

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
              for (final e in inventory.entries)
                countCard(e.key, e.value.length),
              Card(
                child: ListTile(
                  title: const Text('Back To Home'),
                  trailing: Text(backToHome),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'WireGuard, ZeroTier, IPsec, L2TP, SSTP et OpenVPN '
                    'sont inventoriés séparément. Les interfaces PPP/VPN '
                    'n’impliquent pas automatiquement que Neighbor '
                    'Discovery L2 traverse le tunnel.',
                  ),
                ),
              ),
            ],
          ),
  );
}
