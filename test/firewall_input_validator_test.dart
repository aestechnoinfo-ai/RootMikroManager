import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/firewall/firewall_input_validator.dart';

void main() {
  test('validates firewall addresses and ports', () {
    expect(FirewallInputValidator.ipOrCidrOrEmpty('192.168.88.0/24'), isNull);
    expect(FirewallInputValidator.ipOrCidrOrEmpty('999.1.1.1'), isNotNull);
    expect(FirewallInputValidator.ports('80,443,1000-2000'), isNull);
    expect(FirewallInputValidator.ports('70000'), isNotNull);
    expect(
      FirewallInputValidator.ipv4RangeOrCidrOrEmpty(
        '192.168.88.2-192.168.88.254',
      ),
      isNull,
    );
    expect(
      FirewallInputValidator.connectionStates('established,related'),
      isNull,
    );
  });
}
