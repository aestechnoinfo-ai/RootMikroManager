import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/routeros/routeros_service.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_generator_screen.dart';

class _ProfileRouter extends RouterOsService {
  @override
  Future<List<Map<String, String>>> hotspotProfiles() async => [
    {'name': '3-heures'},
    {'name': '1-heure'},
    {'name': '3-heures'},
  ];

  @override
  Future<List<Map<String, String>>> hotspotServers() async =>
      throw StateError('serveurs temporairement indisponibles');

  @override
  Future<List<Map<String, String>>> hotspotUsers() async =>
      throw StateError('utilisateurs temporairement indisponibles');
}

void main() {
  testWidgets(
    'les profils restent sélectionnables si les autres références échouent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: VoucherGeneratorScreen(service: _ProfileRouter())),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 profil(s) disponible(s)'), findsOneWidget);
      final field = tester.widget<DropdownButtonFormField<String>>(
        find.ancestor(
          of: find.text('2 profil(s) disponible(s)'),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );
      expect(field.onChanged, isNotNull);
    },
  );
}
