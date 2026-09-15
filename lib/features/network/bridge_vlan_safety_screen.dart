import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';
import 'bridge_vlan_safety_analyzer.dart';

class BridgeVlanSafetyScreen extends StatefulWidget {
  final RouterOsService service;
  const BridgeVlanSafetyScreen({super.key, required this.service});

  @override
  State<BridgeVlanSafetyScreen> createState() => _BridgeVlanSafetyScreenState();
}

class _BridgeVlanSafetyScreenState extends State<BridgeVlanSafetyScreen> {
  bool loading = true;
  List<Map<String, String>> bridges = [];
  List<Map<String, String>> ports = [];
  List<Map<String, String>> vlans = [];
  List<Map<String, String>> vlanInterfaces = [];
  List<Map<String, String>> ipAddresses = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final data = await Future.wait([
      widget.service.bridges(),
      widget.service.bridgePortsAdvanced(),
      widget.service.bridgeVlans(),
      widget.service.vlanInterfaces(),
      widget.service.ipAddresses(),
    ]);
    bridges = data[0];
    ports = data[1];
    vlans = data[2];
    vlanInterfaces = data[3];
    ipAddresses = data[4];
    if (mounted) setState(() => loading = false);
  }

  IconData iconFor(BridgeRiskLevel level) => switch (level) {
    BridgeRiskLevel.info => Icons.info_outline,
    BridgeRiskLevel.warning => Icons.warning_amber_outlined,
    BridgeRiskLevel.critical => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    final analyzer = const BridgeVlanSafetyAnalyzer();
    final groups =
        <({Map<String, String> bridge, List<BridgeRiskFinding> findings})>[
          for (final bridge in bridges)
            (
              bridge: bridge,
              findings: analyzer.analyze(
                bridge: bridge,
                ports: ports,
                vlans: vlans,
                vlanInterfaces: vlanInterfaces,
                ipAddresses: ipAddresses,
              ),
            ),
        ];
    final critical = groups
        .expand((e) => e.findings)
        .where((e) => e.level == BridgeRiskLevel.critical)
        .length;
    final warnings = groups
        .expand((e) => e.findings)
        .where((e) => e.level == BridgeRiskLevel.warning)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité Bridge VLAN'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'L’audit est conservatif. Il cherche surtout les erreurs capables de couper le management : CPU/bridge absent du VLAN, access PVID incohérent, trunk sans ingress-filtering ou plusieurs VLANs sur des ports untagged.',
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('${bridges.length} bridge(s)')),
                    Chip(label: Text('$critical critique(s)')),
                    Chip(label: Text('$warnings avertissement(s)')),
                  ],
                ),
                const SizedBox(height: 8),
                for (final group in groups)
                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: group.findings.any(
                        (e) => e.level == BridgeRiskLevel.critical,
                      ),
                      leading: Icon(
                        group.findings.any(
                              (e) => e.level == BridgeRiskLevel.critical,
                            )
                            ? Icons.error_outline
                            : group.findings.any(
                                (e) => e.level == BridgeRiskLevel.warning,
                              )
                            ? Icons.warning_amber_outlined
                            : Icons.check_circle_outline,
                      ),
                      title: Text(group.bridge['name'] ?? 'Bridge'),
                      subtitle: Text(
                        'VLAN filtering ${group.bridge['vlan-filtering'] ?? 'no'}',
                      ),
                      children: group.findings.isEmpty
                          ? const [
                              ListTile(
                                title: Text(
                                  'Aucun avertissement simple détecté',
                                ),
                              ),
                            ]
                          : [
                              for (final finding in group.findings)
                                ListTile(
                                  leading: Icon(iconFor(finding.level)),
                                  title: Text(finding.message),
                                ),
                            ],
                    ),
                  ),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Même sans avertissement, validez le chemin réel de management avant activation. Un changement de VLAN peut rendre le routeur inaccessible immédiatement.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
