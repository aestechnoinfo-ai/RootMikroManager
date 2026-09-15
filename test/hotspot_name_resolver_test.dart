import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/vouchers/hotspot_name_resolver.dart';

void main() {
  const resolver = HotspotNameResolver();

  test('préfère le SSID actif', () {
    expect(
      resolver.resolve([
        {'ssid': 'WiFi arrêté', 'disabled': 'true'},
        {'configuration.ssid': 'WiFi clients', 'running': 'true'},
      ]),
      'WiFi clients',
    );
  });

  test('utilise une configuration WiFi puis le secours manuel', () {
    expect(
      resolver.resolve(
        const [],
        configurations: const [
          {'ssid': 'Agence'},
        ],
      ),
      'Agence',
    );
    expect(
      resolver.resolve(const [], fallback: 'Routeur sans WiFi'),
      'Routeur sans WiFi',
    );
  });
}
