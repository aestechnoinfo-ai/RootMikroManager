import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/network_input_validator.dart';

void main() {
  test('validates IPv4 and IPv6 routing inputs', () {
    expect(NetworkInputValidator.routeDestination('0.0.0.0/0'), isNull);
    expect(NetworkInputValidator.ipv6Cidr('2001:db8::/64'), isNull);
    expect(NetworkInputValidator.ipv6Cidr('2001:db8::/129'), isNotNull);
    expect(NetworkInputValidator.ipOrCidr('192.168.10.0/24', label: 'src'), isNull);
    expect(NetworkInputValidator.ipOrCidr('2001:db8::/64', label: 'src'), isNull);
    expect(NetworkInputValidator.ipv6Gateway('fe80::1%ether1'), isNull);
  });
}
