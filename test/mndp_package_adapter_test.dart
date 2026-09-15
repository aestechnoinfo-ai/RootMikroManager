import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/network/network_binding_service.dart';

List<int> field(int type, List<int> data) =>
    [0, type, data.length >> 8, data.length & 255, ...data];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('package decoder preserves identity and official model characters', () async {
    final bytes = [0, 0, 0, 1,
      ...field(1, [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff]),
      ...field(5, utf8.encode(' Mon Routeur ')),
      ...field(12, utf8.encode(' hAP ac² ')),
      ...field(17, [192, 0, 2, 8]),
    ];
    final row = await NetworkBindingService().decodeMndpRow({
      'raw': base64Encode(bytes), 'address': 'fe80::1',
    });
    expect(row['address'], '192.0.2.8');
    expect(row['identity'], 'Mon Routeur');
    expect(row['board'], 'hAP ac²');
    expect(row['mac-address'], 'AA:BB:CC:DD:EE:FF');
  });
  test('truncated MNDP is discarded without propagating an exception', () async {
    final row = await NetworkBindingService().decodeMndpRow({
      'raw': base64Encode([0, 0, 0, 0, 0, 1, 0, 6, 1]),
    });
    expect(row, isEmpty);
  });
  test('IPv6 alone is not offered as the IPv4 registration address', () async {
    final bytes = [0, 0, 0, 1,
      ...field(1, [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff]),
      ...field(5, utf8.encode('Router')),
    ];
    expect(await NetworkBindingService().decodeMndpRow({
      'raw': base64Encode(bytes), 'address': 'fe80::1',
    }), isEmpty);
  });
}
