import 'wifi_provisioning_screen.dart';
import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class WifiCapsmanScreen extends StatefulWidget {
  final RouterOsService service;
  const WifiCapsmanScreen({super.key, required this.service});
  @override
  State<WifiCapsmanScreen> createState() => _S();
}

class _S extends State<WifiCapsmanScreen> {
  bool loading = true;
  List<Map<String, String>> caps = [], prov = [];
  Map<String, int> inventory = const {'modern': 0, 'legacy': 0};
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final r = await Future.wait([
      widget.service.wifiRemoteCaps(),
      widget.service.wifiProvisioning(),
    ]);
    caps = r[0];
    prov = r[1];
    inventory = await widget.service.wifiBackendInventory();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('WiFi CAPsMAN'),
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
                      const Text(
                        'Le nouveau WiFi CAPsMAN et le CAPsMAN legacy restent deux familles distinctes.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Interfaces WiFi modernes : ${inventory['modern'] ?? 0}',
                      ),
                      Text(
                        'Interfaces Wireless legacy : ${inventory['legacy'] ?? 0}',
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ExpansionTile(
                  title: Text('Remote CAP (${caps.length})'),
                  leading: const Icon(Icons.router_outlined),
                  children: [
                    for (final r in caps)
                      ListTile(
                        title: Text(r['identity'] ?? r['common-name'] ?? 'CAP'),
                        subtitle: Text(
                          [
                            if ((r['address'] ?? '').isNotEmpty) r['address']!,
                            if ((r['board-name'] ?? '').isNotEmpty)
                              r['board-name']!,
                            if ((r['version'] ?? '').isNotEmpty)
                              'ROS ${r['version']}',
                          ].join(' • '),
                        ),
                      ),
                  ],
                ),
              ),
              Card(
                child: ExpansionTile(
                  title: Text('Provisioning (${prov.length})'),
                  leading: const Icon(Icons.auto_awesome_motion_outlined),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Gérer les règles de provisioning'),
                      onTap: () => AppRouter.pushNamed(
                        context,
                        AppRoutes.hubWifiProvisioning,
                      ).then((_) => load()),
                    ),
                    for (final r in prov)
                      ListTile(
                        title: Text(r['action'] ?? 'create-enabled'),
                        subtitle: Text(
                          [
                            if ((r['radio-mac'] ?? '').isNotEmpty)
                              r['radio-mac']!,
                            if ((r['master-configuration'] ?? '').isNotEmpty)
                              'Master ${r['master-configuration']}',
                          ].join(' • '),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
  );
}
