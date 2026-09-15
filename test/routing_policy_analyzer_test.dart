import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/routing_policy_analyzer.dart';

void main() {
  test('warns about default route and invalid scope relation', () {
    final issues = RoutingPolicyAnalyzer.ipv4Route(
      destination: '0.0.0.0/0',
      gateway: '192.168.1.1',
      table: 'main',
      distance: 1,
      scope: 10,
      targetScope: 10,
      checkGateway: 'ping',
    );
    expect(issues.any((e) => e.code == 'main-default'), isTrue);
    expect(issues.any((e) => e.code == 'scope-order'), isTrue);
  });

  test('blocks deleting a referenced routing table', () {
    final issues = RoutingPolicyAnalyzer.tableDelete(
      name: 'wan2',
      ipv4Routes: const [
        {'routing-table': 'wan2'}
      ],
      ipv6Routes: const [],
      rules: const [],
    );
    expect(issues.any((e) => e.code == 'table-referenced' && e.critical), isTrue);
  });

  test('flags broad blocking routing rule', () {
    final issues = RoutingPolicyAnalyzer.rule(
      action: 'drop',
      source: '',
      destination: '',
      table: 'main',
    );
    expect(issues.any((e) => e.code == 'broad-rule' && e.critical), isTrue);
  });
}
