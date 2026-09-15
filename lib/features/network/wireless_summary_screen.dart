import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class WirelessSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const WirelessSummaryScreen({super.key, required this.service});
  @override
  State<WirelessSummaryScreen> createState() => _WirelessSummaryScreenState();
}

class _WirelessSummaryScreenState extends State<WirelessSummaryScreen> {
  bool loading = true;
  int interfaces = 0, wifi = 0, legacy = 0, clients = 0, profiles = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final i = await widget.service.wirelessInterfacesAll();
    final r = await widget.service.wirelessRegistrationsAll();
    final s = await widget.service.wirelessSecurityProfilesAll();
    interfaces = i.length;
    wifi = i.where((e) => e['_backend'] == 'WiFi').length;
    legacy = i.where((e) => e['_backend'] == 'Wireless').length;
    clients = r.length;
    profiles = s.length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé Wi‑Fi'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _c('Interfaces radio', interfaces, Icons.wifi),
              _c('Nouveau WiFi', wifi, Icons.router_outlined),
              _c('Wireless classique', legacy, Icons.settings_input_antenna),
              _c('Clients enregistrés', clients, Icons.devices_outlined),
              _c('Profils sécurité', profiles, Icons.security_outlined),
            ],
          ),
  );
  Widget _c(String l, int v, IconData i) => Card(
    child: ListTile(
      leading: Icon(i),
      title: Text(l),
      trailing: Text('$v', style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
