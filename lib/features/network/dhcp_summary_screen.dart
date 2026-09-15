import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class DhcpSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const DhcpSummaryScreen({super.key, required this.service});

  @override
  State<DhcpSummaryScreen> createState() => _DhcpSummaryScreenState();
}

class _DhcpSummaryScreenState extends State<DhcpSummaryScreen> {
  bool loading = true;
  int servers = 0;
  int networks = 0;
  int pools = 0;
  int leases = 0;
  int dynamicLeases = 0;
  int boundLeases = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);

    final result = await Future.wait([
      widget.service.dhcpServers(),
      widget.service.dhcpNetworks(),
      widget.service.ipPools(),
      widget.service.dhcpLeases(),
    ]);

    servers = result[0].length;
    networks = result[1].length;
    pools = result[2].length;
    leases = result[3].length;
    dynamicLeases = result[3]
        .where((r) => r['dynamic'] == 'yes' || r['dynamic'] == 'true')
        .length;
    boundLeases = result[3].where((r) => (r['status'] ?? '') == 'bound').length;

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé DHCP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _card('Serveurs DHCP', servers, Icons.dns_outlined),
              _card('Réseaux', networks, Icons.account_tree_outlined),
              _card('IP Pools', pools, Icons.hub_outlined),
              _card('Baux totaux', leases, Icons.devices_outlined),
              _card('Baux dynamiques', dynamicLeases, Icons.bolt),
              _card('Baux bound', boundLeases, Icons.link_outlined),
            ],
          ),
  );

  Widget _card(String label, int value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text('$value', style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
