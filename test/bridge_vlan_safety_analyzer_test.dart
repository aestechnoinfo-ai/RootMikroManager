import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/bridge_vlan_safety_analyzer.dart';

void main() {
  test('flags missing CPU membership and untagged multi-VLAN entry', () {
    final findings = const BridgeVlanSafetyAnalyzer().analyze(
      bridge: const {'.id': '*1', 'name': 'bridge1', 'vlan-filtering': 'no'},
      ports: const [
        {
          'bridge': 'bridge1',
          'interface': 'ether2',
          'pvid': '10',
          'frame-types': 'admit-only-untagged-and-priority-tagged',
          'ingress-filtering': 'yes',
        }
      ],
      vlans: const [
        {
          'bridge': 'bridge1',
          'vlan-ids': '10,20',
          'tagged': 'ether1',
          'untagged': 'ether2',
        }
      ],
      vlanInterfaces: const [],
      ipAddresses: const [],
    );

    expect(
      findings.any((e) => e.level == BridgeRiskLevel.critical && e.message.contains('CPU/bridge')),
      isFalse,
      reason: 'CPU absence is warning before vlan-filtering is enabled.',
    );
    expect(
      findings.any((e) => e.level == BridgeRiskLevel.critical && e.message.contains('plusieurs VLANs')),
      isTrue,
    );
  });

  test('blocks CPU absence when filtering is already active', () {
    final findings = const BridgeVlanSafetyAnalyzer().analyze(
      bridge: const {'.id': '*1', 'name': 'bridge1', 'vlan-filtering': 'yes'},
      ports: const [],
      vlans: const [
        {'bridge': 'bridge1', 'vlan-ids': '99', 'tagged': 'ether1', 'untagged': ''}
      ],
      vlanInterfaces: const [],
      ipAddresses: const [],
    );

    expect(
      findings.any((e) => e.level == BridgeRiskLevel.critical && e.message.contains('CPU/bridge')),
      isTrue,
    );
  });
}
