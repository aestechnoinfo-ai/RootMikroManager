import 'bridge_vlan_validator.dart';

enum BridgeRiskLevel { info, warning, critical }

class BridgeRiskFinding {
  final BridgeRiskLevel level;
  final String message;
  const BridgeRiskFinding(this.level, this.message);
}

class BridgeVlanSafetyAnalyzer {
  const BridgeVlanSafetyAnalyzer();

  List<BridgeRiskFinding> analyze({
    required Map<String, String> bridge,
    required List<Map<String, String>> ports,
    required List<Map<String, String>> vlans,
    required List<Map<String, String>> vlanInterfaces,
    required List<Map<String, String>> ipAddresses,
  }) {
    final findings = <BridgeRiskFinding>[];
    final name = bridge['name'] ?? '';
    final filtered = _yes(bridge['vlan-filtering']);
    final bridgePorts = ports.where((e) => e['bridge'] == name).toList();
    final bridgeVlans = vlans.where((e) => e['bridge'] == name).toList();

    if (bridgeVlans.isEmpty) {
      findings.add(
        const BridgeRiskFinding(
          BridgeRiskLevel.critical,
          'Aucune entrée Bridge VLAN Table n’est configurée.',
        ),
      );
    }

    final cpuMember = bridgeVlans.any((row) {
      final tagged = BridgeVlanValidator.splitMembers(row['tagged']);
      final untagged = BridgeVlanValidator.splitMembers(row['untagged']);
      return tagged.contains(name) || untagged.contains(name);
    });
    if (!cpuMember) {
      findings.add(
        BridgeRiskFinding(
          filtered ? BridgeRiskLevel.critical : BridgeRiskLevel.warning,
          'Le port CPU/bridge « $name » n’apparaît dans aucune entrée VLAN explicite.',
        ),
      );
    }

    final vlanIfaces = vlanInterfaces
        .where((e) => e['interface'] == name)
        .toList();
    final vlanIfaceNames = vlanIfaces
        .map((e) => e['name'])
        .whereType<String>()
        .toSet();
    final hasBridgeIp = ipAddresses.any((e) => e['interface'] == name);
    final hasVlanIp = ipAddresses.any(
      (e) => vlanIfaceNames.contains(e['interface']),
    );
    if (!hasBridgeIp && !hasVlanIp) {
      findings.add(
        const BridgeRiskFinding(
          BridgeRiskLevel.warning,
          'Aucune adresse IP de management n’est détectée sur le bridge ni sur une interface VLAN portée par ce bridge.',
        ),
      );
    }

    for (final port in bridgePorts) {
      final iface = port['interface'] ?? '—';
      final pvid = port['pvid'] ?? '1';
      final frame = port['frame-types'] ?? 'admit-all';
      final ingress = _yes(port['ingress-filtering']);
      final disabled = _yes(port['disabled']);
      if (disabled) continue;

      if (frame == 'admit-only-vlan-tagged' && !ingress) {
        findings.add(
          BridgeRiskFinding(
            BridgeRiskLevel.warning,
            '$iface : trunk probable sans ingress-filtering.',
          ),
        );
      }
      if (frame == 'admit-only-untagged-and-priority-tagged') {
        final pvidInt = int.tryParse(pvid);
        final match = bridgeVlans.any((v) {
          final ids = BridgeVlanValidator.expandVlanIds(v['vlan-ids'] ?? '');
          final untagged = BridgeVlanValidator.splitMembers(
            v['current-untagged'] ?? v['untagged'],
          );
          return pvidInt != null &&
              ids.contains(pvidInt) &&
              untagged.contains(iface);
        });
        if (!match) {
          findings.add(
            BridgeRiskFinding(
              BridgeRiskLevel.warning,
              '$iface : port access PVID $pvid sans appartenance untagged correspondante détectée.',
            ),
          );
        }
      }
      if (pvid == '1' && frame == 'admit-all') {
        findings.add(
          BridgeRiskFinding(
            BridgeRiskLevel.info,
            '$iface : PVID 1 + admit-all ; vérifiez que l’accès non tagué est volontaire.',
          ),
        );
      }
    }

    for (final row in bridgeVlans) {
      final tagged = BridgeVlanValidator.splitMembers(row['tagged']);
      final untagged = BridgeVlanValidator.splitMembers(row['untagged']);
      final overlap = tagged.intersection(untagged);
      if (overlap.isNotEmpty) {
        findings.add(
          BridgeRiskFinding(
            BridgeRiskLevel.critical,
            'VLAN ${row['vlan-ids'] ?? '—'} : ${overlap.join(', ')} est déclaré tagged et untagged.',
          ),
        );
      }
      final ids = row['vlan-ids'] ?? '';
      if (BridgeVlanValidator.containsMultipleVlans(ids) &&
          untagged.isNotEmpty) {
        findings.add(
          BridgeRiskFinding(
            BridgeRiskLevel.critical,
            'VLAN $ids : plusieurs VLANs partagent une entrée comportant des ports untagged.',
          ),
        );
      }
    }

    if (filtered) {
      findings.add(
        const BridgeRiskFinding(
          BridgeRiskLevel.info,
          'VLAN Filtering est déjà actif : toute modification du VLAN de management doit être traitée comme une opération à risque.',
        ),
      );
    }
    return findings;
  }

  bool _yes(String? value) => value == 'yes' || value == 'true';
}
