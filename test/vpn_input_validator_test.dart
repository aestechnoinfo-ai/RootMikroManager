import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/vpn_input_validator.dart';

void main() {
  test('validates WireGuard and ZeroTier inputs', () {
    expect(
      VpnInputValidator.allowedAddresses('10.10.10.2/32,192.168.50.0/24'),
      isNull,
    );
    expect(VpnInputValidator.allowedAddresses('10.10.10.2/99'), isNotNull);
    expect(VpnInputValidator.port('13231'), isNull);
    expect(VpnInputValidator.port('70000'), isNotNull);
    expect(VpnInputValidator.zeroTierNetworkId('8056c2e21c000001'), isNull);
    expect(VpnInputValidator.zeroTierNetworkId('bad'), isNotNull);
  });
}
