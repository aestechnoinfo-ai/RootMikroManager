import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotSetupSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotSetupSummaryScreen({super.key, required this.service});
  @override
  State<HotspotSetupSummaryScreen> createState() =>
      _HotspotSetupSummaryScreenState();
}

class _HotspotSetupSummaryScreenState extends State<HotspotSetupSummaryScreen> {
  bool loading = true;
  int servers = 0,
      serverProfiles = 0,
      userProfiles = 0,
      pools = 0,
      users = 0,
      active = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final r = await Future.wait([
      widget.service.hotspotServers(),
      widget.service.hotspotServerProfiles(),
      widget.service.hotspotProfiles(),
      widget.service.ipPools(),
      widget.service.hotspotUsers(),
      widget.service.activeUsers(),
    ]);
    servers = r[0].length;
    serverProfiles = r[1].length;
    userProfiles = r[2].length;
    pools = r[3].length;
    users = r[4].length;
    active = r[5].length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé configuration Hotspot'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _c('Hotspot Servers', servers, Icons.router_outlined),
              _c(
                'Server Profiles',
                serverProfiles,
                Icons.settings_ethernet_outlined,
              ),
              _c('User Profiles', userProfiles, Icons.manage_accounts_outlined),
              _c('IP Pools', pools, Icons.hub_outlined),
              _c('Utilisateurs', users, Icons.people_outline),
              _c('Sessions actives', active, Icons.wifi_tethering),
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
