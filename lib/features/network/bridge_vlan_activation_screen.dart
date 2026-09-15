import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';
import 'bridge_vlan_safety_analyzer.dart';

class BridgeVlanActivationScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String> bridge;

  const BridgeVlanActivationScreen({
    super.key,
    required this.service,
    required this.bridge,
  });

  @override
  State<BridgeVlanActivationScreen> createState() =>
      _BridgeVlanActivationScreenState();
}

class _BridgeVlanActivationScreenState
    extends State<BridgeVlanActivationScreen> {
  final confirmation = TextEditingController();
  bool loading = true;
  bool working = false;
  List<BridgeRiskFinding> findings = [];

  String get bridgeName => widget.bridge['name'] ?? '';
  bool get enabled =>
      widget.bridge['vlan-filtering'] == 'yes' ||
      widget.bridge['vlan-filtering'] == 'true';
  bool get hasCritical =>
      findings.any((e) => e.level == BridgeRiskLevel.critical);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final data = await Future.wait([
      widget.service.bridgePortsAdvanced(),
      widget.service.bridgeVlans(),
      widget.service.vlanInterfaces(),
      widget.service.ipAddresses(),
    ]);
    findings = const BridgeVlanSafetyAnalyzer().analyze(
      bridge: widget.bridge,
      ports: data[0],
      vlans: data[1],
      vlanInterfaces: data[2],
      ipAddresses: data[3],
    );
    if (mounted) setState(() => loading = false);
  }

  Future<void> apply() async {
    if (working) return;
    final id = widget.bridge['.id'];
    if (id == null || bridgeName.isEmpty) return;

    if (!enabled && hasCritical) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Activation bloquée : corrigez d’abord les risques critiques.',
          ),
        ),
      );
      return;
    }
    if (!enabled && confirmation.text.trim() != bridgeName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tapez exactement « $bridgeName » pour confirmer.'),
        ),
      );
      return;
    }

    final action = enabled ? 'désactiver' : 'activer';
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              '${enabled ? 'Désactiver' : 'Activer'} VLAN Filtering ?',
            ),
            content: Text(
              enabled
                  ? 'Le filtrage VLAN sera désactivé sur $bridgeName.'
                  : 'Cette opération peut couper immédiatement l’accès IP au routeur si le VLAN de management, le port CPU/bridge ou le trunk ne sont pas correctement configurés.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    setState(() => working = true);
    try {
      await widget.service.setBridgeVlanFiltering(id, !enabled);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => working = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  IconData iconFor(BridgeRiskLevel level) => switch (level) {
    BridgeRiskLevel.info => Icons.info_outline,
    BridgeRiskLevel.warning => Icons.warning_amber_outlined,
    BridgeRiskLevel.critical => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('VLAN Filtering sécurisé'),
      actions: [
        IconButton(
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(
                    enabled
                        ? Icons.verified_user_outlined
                        : Icons.shield_outlined,
                  ),
                  title: Text(bridgeName.isEmpty ? 'Bridge' : bridgeName),
                  subtitle: Text(
                    'VLAN Filtering : ${enabled ? 'ACTIF' : 'désactivé'}',
                  ),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Avant activation, vérifiez le VLAN de management, l’appartenance du port CPU/bridge, les trunks et les PVID des ports access. RootMikroManager bloque l’activation lorsqu’un risque critique simple est détecté.',
                  ),
                ),
              ),
              if (findings.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucun avertissement simple détecté'),
                  ),
                ),
              for (final finding in findings)
                Card(
                  child: ListTile(
                    leading: Icon(iconFor(finding.level)),
                    title: Text(finding.message),
                  ),
                ),
              if (!enabled) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: confirmation,
                  decoration: InputDecoration(
                    labelText: 'Confirmation',
                    helperText: 'Tapez exactement $bridgeName',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: working ? null : apply,
                icon: Icon(
                  enabled
                      ? Icons.shield_outlined
                      : Icons.verified_user_outlined,
                ),
                label: Text(
                  enabled
                      ? 'Désactiver VLAN Filtering'
                      : 'Activer VLAN Filtering',
                ),
              ),
            ],
          ),
  );

  @override
  void dispose() {
    confirmation.dispose();
    super.dispose();
  }
}
