import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/discovery/discovery_candidate.dart';
import 'package:root_mikro_manager/features/discovery/router_candidate_save_screen.dart';

void main() {
  testWidgets('registration requires validation and a successful API test', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RouterCandidateSaveScreen(
          candidate: DiscoveryCandidate(
            source: 'MNDP',
            identity: 'Mon Routeur',
            address: '192.0.2.1',
            macAddress: 'AA:BB:CC:DD:EE:FF',
            board: 'hAP ac²',
          ),
        ),
      ),
    );
    final save = find.widgetWithText(FilledButton, 'Enregistrer');
    await tester.scrollUntilVisible(
      save,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.tap(find.text('Tester la connexion'));
    await tester.pump();
    expect(find.text('Mot de passe obligatoire'), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });
}
