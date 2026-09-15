import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/wifi_wireless_safety_analyzer.dart';

void main() {
  test('flags broad reject access rule', () {
    final issues=WifiWirelessSafetyAnalyzer.accessRule(
      action:'reject',
      mac:'',
      interfaceName:'',
      ssidRegexp:'',
      signalRange:'',
    );
    expect(issues.any((e)=>e.code=='broad-reject'&&e.critical),isTrue);
  });

  test('flags broad provisioning rule', () {
    final issues=WifiWirelessSafetyAnalyzer.provisioning(
      action:'create-enabled',
      radioMac:'',
      supportedBands:'',
      identityRegexp:'',
      masterConfiguration:'cfg-main',
    );
    expect(
      issues.any((e)=>e.code=='broad-provisioning'&&e.critical),
      isTrue,
    );
  });

  test('flags missing authentication', () {
    final issues=WifiWirelessSafetyAnalyzer.security(
      authentication:'',
      passphrase:'',
    );
    expect(issues.any((e)=>e.code=='auth-empty'&&e.critical),isTrue);
  });
}
