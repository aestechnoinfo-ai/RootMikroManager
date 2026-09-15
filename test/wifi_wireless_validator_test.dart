import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/wifi_wireless_validator.dart';

void main() {
  test('validates WiFi MAC, VLAN, signal and passphrase', () {
    expect(WifiWirelessValidator.macOrEmpty('AA:BB:CC:DD:EE:FF'), isNull);
    expect(WifiWirelessValidator.macOrEmpty('AA:BB:CC'), isNotNull);
    expect(WifiWirelessValidator.vlanOrEmpty('4094'), isNull);
    expect(WifiWirelessValidator.vlanOrEmpty('4095'), isNotNull);
    expect(WifiWirelessValidator.signalRangeOrEmpty('-120..-70'), isNull);
    expect(
      WifiWirelessValidator.passphrase(
        '12345678',
        authentication: 'wpa2-psk',
      ),
      isNull,
    );
    expect(
      WifiWirelessValidator.passphrase(
        'short',
        authentication: 'wpa2-psk',
      ),
      isNotNull,
    );
  });
}
