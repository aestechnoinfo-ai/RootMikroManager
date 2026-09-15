import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/network/mndp_scanner.dart';

List<int> tlv(int type, List<int> value) => [
  0,
  type,
  value.length >> 8,
  value.length & 255,
  ...value,
];
Uint8List packet(List<int> fields) => Uint8List.fromList([
  0,
  0,
  0,
  0,
  ...tlv(1, [1, 2, 3, 4, 5, 6]),
  ...fields,
]);

void main() {
  test('uses source IPv4 rather than another advertised interface', () {
    final row = MndpScanner.decode(
      packet([
        ...tlv(17, [10, 1, 2, 3]),
        ...tlv(5, utf8.encode('Routeur @ site')),
        ...tlv(12, utf8.encode('hAP ac²')),
      ]),
      '192.0.2.1',
    )!;
    expect(row['address'], '192.0.2.1');
    expect(row['board'], 'hAP ac²');
    expect(row['identity'], 'Routeur @ site');
  });
  test('missing identity does not hide a neighbor', () {
    expect(
      MndpScanner.decode(packet([]), '192.0.2.1')?['mac-address'],
      '01:02:03:04:05:06',
    );
  });
  test('supports legacy Latin-1 identity', () {
    expect(
      MndpScanner.decode(
        packet(tlv(5, [0x63, 0x61, 0x66, 0xe9])),
        '192.0.2.1',
      )?['identity'],
      'café',
    );
  });
  test('rejects truncated TLVs and IPv6 sources', () {
    expect(MndpScanner.decode(packet([0, 5, 0, 9, 1]), '192.0.2.1'), isNull);
    expect(MndpScanner.decode(packet([]), 'fe80::1'), isNull);
  });
}
