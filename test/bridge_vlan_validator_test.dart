import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/network/bridge_vlan_validator.dart';

void main() {
  group('BridgeVlanValidator', () {
    test('accepts single VLAN, range and mixed list', () {
      expect(BridgeVlanValidator.validVlanIds('10'), isTrue);
      expect(BridgeVlanValidator.validVlanIds('100-120'), isTrue);
      expect(BridgeVlanValidator.validVlanIds('10,20,100-110'), isTrue);
    });

    test('rejects reserved or malformed VLAN IDs', () {
      expect(BridgeVlanValidator.validVlanIds('0'), isFalse);
      expect(BridgeVlanValidator.validVlanIds('4095'), isFalse);
      expect(BridgeVlanValidator.validVlanIds('20-10'), isFalse);
      expect(BridgeVlanValidator.validVlanIds('10,,20'), isFalse);
    });

    test('expands VLAN IDs safely', () {
      expect(BridgeVlanValidator.expandVlanIds('10,20-22'), {10, 20, 21, 22});
    });
  });
}
