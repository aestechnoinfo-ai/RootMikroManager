import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class WifiConfigSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const WifiConfigSummaryScreen({super.key, required this.service});
  @override
  State<WifiConfigSummaryScreen> createState() => _S();
}

class _S extends State<WifiConfigSummaryScreen> {
  bool loading = true;
  List<int> n = [0, 0, 0, 0, 0, 0];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final r = await Future.wait([
      widget.service.wifiInterfacesFor('modern'),
      widget.service.wifiInterfacesFor('legacy'),
      widget.service.wifiAccessList('modern'),
      widget.service.wifiAccessList('legacy'),
      widget.service.wirelessRegistrationsAll(),
      widget.service.wifiRemoteCaps(),
    ]);
    n = List.generate(6, (i) => r[i].length);
    if (mounted) setState(() => loading = false);
  }

  Widget c(String l, int v, IconData i) => Card(
    child: ListTile(
      leading: Icon(i),
      title: Text(l),
      trailing: Text('$v', style: Theme.of(context).textTheme.titleLarge),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé configuration WiFi'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              c('Interfaces WiFi modernes', n[0], Icons.wifi),
              c('Interfaces Wireless legacy', n[1], Icons.wifi_tethering),
              c('Access List moderne', n[2], Icons.rule_outlined),
              c('Access List legacy', n[3], Icons.rule_folder_outlined),
              c('Clients enregistrés', n[4], Icons.devices_outlined),
              c('Remote CAP', n[5], Icons.router_outlined),
            ],
          ),
  );
}
