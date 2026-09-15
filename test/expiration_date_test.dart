import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/routeros/routeros_expiration_date.dart';

void main() {
  group('RouterOsExpirationDate', () {
    test('lit le format historique RouterOS 6', () {
      expect(
        RouterOsExpirationDate.tryParse('aug/31/2026 16:05:11'),
        DateTime(2026, 8, 31, 16, 5, 11),
      );
    });

    test('lit le format ISO RouterOS 7.13+', () {
      expect(
        RouterOsExpirationDate.tryParse('2026-08-31 16:05:11'),
        DateTime(2026, 8, 31, 16, 5, 11),
      );
    });

    test('refuse une date invalide au lieu de la normaliser', () {
      expect(RouterOsExpirationDate.tryParse('2026-02-31 12:00:00'), null);
    });

    test('détecte une expiration à la seconde près', () {
      final now = DateTime.utc(2026, 8, 31, 16, 5, 11);
      expect(
        RouterOsExpirationDate.isExpired('2026-08-31 16:05:11', now),
        true,
      );
      expect(
        RouterOsExpirationDate.isExpired('sep/01/2026 00:00:00', now),
        false,
      );
    });
  });
}
