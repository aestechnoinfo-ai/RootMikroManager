import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/dhcp_dns_safety_analyzer.dart';

void main() {
  test('detects duplicate active DHCP server on one interface', () {
    final issues = DhcpDnsSafetyAnalyzer.dhcpServer(
      interfaceName: 'bridge-lan',
      addressPool: 'pool-lan',
      relay: '0.0.0.0',
      servers: const [
        {
          '.id': '*1',
          'name': 'dhcp-lan',
          'interface': 'bridge-lan',
          'disabled': 'no',
        },
      ],
      currentId: null,
    );
    expect(issues.any((e) => e.code == 'duplicate-interface' && e.critical), isTrue);
  });

  test('warns when remote DNS is enabled', () {
    final issues = DhcpDnsSafetyAnalyzer.dnsResolver(
      allowRemoteRequests: true,
      dohServer: 'https://dns.example/dns-query',
      verifyDohCertificate: false,
    );
    expect(issues.any((e) => e.code == 'remote-dns'), isTrue);
    expect(issues.any((e) => e.code == 'doh-cert'), isTrue);
  });
}
