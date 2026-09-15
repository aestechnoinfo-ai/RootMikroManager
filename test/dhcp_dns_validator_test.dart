import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/network_input_validator.dart';

void main() {
  test('validates DHCP and DNS network inputs', () {
    expect(NetworkInputValidator.ipv4Cidr('192.168.88.0/24'), isNull);
    expect(NetworkInputValidator.ipv4Cidr('192.168.88.0/33'), isNotNull);
    expect(NetworkInputValidator.mac('AA:BB:CC:DD:EE:FF'), isNull);
    expect(NetworkInputValidator.ipv4List('1.1.1.1,8.8.8.8'), isNull);
    expect(NetworkInputValidator.ipv4List('1.1.1.1,bad'), isNotNull);
    expect(
      NetworkInputValidator.routerOsDuration('1d2h30m', label: 'TTL'),
      isNull,
    );
    expect(
      NetworkInputValidator.httpUrl(
        'https://dns.example/dns-query',
        label: 'DoH',
      ),
      isNull,
    );
  });
}
