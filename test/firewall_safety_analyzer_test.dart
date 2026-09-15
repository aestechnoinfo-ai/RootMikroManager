import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/firewall/firewall_safety_analyzer.dart';

void main() {
  test('flags broad input drop', () {
    final issues = FirewallSafetyAnalyzer.filterRule(
      chain: 'input',
      action: 'drop',
      protocol: '',
      srcAddress: '',
      dstPort: '',
      inInterface: '',
      connectionState: '',
    );
    expect(
      issues.any((e) => e.code == 'broad-input-block' && e.critical),
      isTrue,
    );
  });

  test('warns about fasttrack requirements', () {
    final issues = FirewallSafetyAnalyzer.filterRule(
      chain: 'forward',
      action: 'fasttrack-connection',
      protocol: 'tcp',
      srcAddress: '',
      dstPort: '',
      inInterface: '',
      connectionState: 'established,related',
    );
    expect(issues.any((e) => e.code == 'fasttrack-bypass'), isTrue);
  });

  test('rejects dst-nat without destination target', () {
    final issues = FirewallSafetyAnalyzer.natRule(
      chain: 'dstnat',
      action: 'dst-nat',
      protocol: 'tcp',
      dstPort: '443',
      toAddresses: '',
      toPorts: '8443',
    );
    expect(
      issues.any((e) => e.code == 'dstnat-target' && e.critical),
      isTrue,
    );
  });
}
