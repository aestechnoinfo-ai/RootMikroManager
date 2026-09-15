import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/hotspot/hotspot_profile_config.dart';
import 'package:root_mikro_manager/features/hotspot/mikhmon_time_parser.dart';

void main() {
  test('normalise les durées humaines cumulées pour RouterOS', () {
    expect(MikhmonTimeParser.normalize('24'), '1d');
    expect(MikhmonTimeParser.normalize('24h'), '1d');
    expect(MikhmonTimeParser.normalize('28h30min'), '1d4h30m');
    expect(MikhmonTimeParser.normalize(' 1d 4H 30 min '), '1d4h30m');
    expect(MikhmonTimeParser.normalize('1 journée'), '1d');
    expect(MikhmonTimeParser.normalize('2 jours'), '2d');
    expect(MikhmonTimeParser.normalize('4w'), '4w');
    expect(MikhmonTimeParser.normalize('1m'), '1m');
    expect(MikhmonTimeParser.normalize('3 mois'), '12w6d');
  });

  test('refuse les durées partielles, nulles et inconnues', () {
    for (final value in ['', '0h', '1hxyz', '-2h', '1.5h']) {
      expect(() => MikhmonTimeParser.normalize(value), throwsFormatException);
    }
  });

  test('on-login crée une expiration individuelle sans variable i', () {
    final script = RootMikroManagerProfileScriptCodec.buildOnLogin(
      const HotspotProfileConfig(
        name: '3-heures',
        expirationMode: HotspotExpirationMode.removeAndRecord,
        validity: '180 min',
      ),
    );
    expect(script, contains('interval="3h"'));
    expect(script, contains('on-event=\$expiryEvent'));
    expect(script, contains('disabled=yes'));
    expect(script, contains('expre=1;'));
    expect(script, contains('/ip hotspot active remove'));
    expect(script, contains('/system scheduler remove'));
    expect(RegExp(r'\b(?:local|foreach|for)\s+i\b').hasMatch(script), isFalse);
  });
}
