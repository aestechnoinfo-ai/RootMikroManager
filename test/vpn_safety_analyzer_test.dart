import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/vpn_safety_analyzer.dart';

void main() {
  test('flags WireGuard default route', () {
    final issues=VpnSafetyAnalyzer.wireGuardPeer(
      allowed:'0.0.0.0/0',
      endpoint:'vpn.example.net',
      keepalive:25,
    );
    expect(issues.any((e)=>e.code=='default-route'&&e.critical),isTrue);
  });

  test('flags ZeroTier default route', () {
    final issues=VpnSafetyAnalyzer.zeroTier(
      allowDefault:true,
      allowGlobal:false,
    );
    expect(issues.any((e)=>e.code=='zt-default'&&e.critical),isTrue);
  });
}
