import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';

class BridgeVlanCapabilityScreen extends StatefulWidget {
  final RouterOsService service;
  const BridgeVlanCapabilityScreen({super.key, required this.service});

  @override
  State<BridgeVlanCapabilityScreen> createState() =>
      _BridgeVlanCapabilityScreenState();
}

class _BridgeVlanCapabilityScreenState
    extends State<BridgeVlanCapabilityScreen> {
  bool loading = true;
  Map<String, String> resource = {};
  Map<String, String> routerboard = {};
  List<Map<String, String>> bridges = [];
  List<Map<String, String>> ports = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await Future.wait([
      widget.service.resource(),
      widget.service.routerboard(),
      widget.service.bridges(),
      widget.service.bridgePortsAdvanced(),
    ]);
    resource = data[0] as Map<String, String>;
    routerboard = data[1] as Map<String, String>;
    bridges = data[2] as List<Map<String, String>>;
    ports = data[3] as List<Map<String, String>>;
    if (mounted) setState(() => loading = false);
  }

  bool get listVlan {
    final match = RegExp(
      r'^(\d+)\.(\d+)',
    ).firstMatch(resource['version'] ?? '');
    if (match == null) return false;
    final major = int.tryParse(match.group(1)!) ?? 0;
    final minor = int.tryParse(match.group(2)!) ?? 0;
    return major > 7 || (major == 7 && minor >= 17);
  }

  @override
  Widget build(BuildContext context) {
    final hw = ports.where((e) => e['hw'] == 'yes').length;
    final activeFiltering = bridges
        .where((e) => e['vlan-filtering'] == 'yes')
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibilité Bridge VLAN'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('RouterOS'),
                    trailing: Text(resource['version'] ?? '—'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Board'),
                    trailing: Text(
                      resource['board-name'] ?? routerboard['model'] ?? '—',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Bridges avec VLAN filtering'),
                    trailing: Text('$activeFiltering/${bridges.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Ports avec flag HW'),
                    trailing: Text('$hw/${ports.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Interface Lists dans Bridge VLAN'),
                    subtitle: Text(
                      listVlan
                          ? 'Disponible : RouterOS 7.17+ détecté. Les noms de listes peuvent être utilisés dans tagged/untagged.'
                          : 'Non proposé dans l’éditeur : nécessite RouterOS 7.17+.',
                    ),
                    leading: Icon(
                      listVlan
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                    ),
                  ),
                ),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Le flag HW visible sur les ports est un indice pratique, pas une garantie universelle de performance. Le support matériel de Bridge VLAN Filtering dépend du modèle et du switch chip ; vérifiez la documentation MikroTik du matériel avant un déploiement important.',
                    ),
                  ),
                ),
                for (final bridge in bridges)
                  Card(
                    child: ListTile(
                      title: Text(bridge['name'] ?? '—'),
                      subtitle: Text(
                        'vlan-filtering ${bridge['vlan-filtering'] ?? 'no'} • '
                        'protocol ${bridge['protocol-mode'] ?? '—'} • '
                        'frame-types ${bridge['frame-types'] ?? '—'}',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
