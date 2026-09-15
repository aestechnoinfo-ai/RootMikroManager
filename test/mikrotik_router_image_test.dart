import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/shared/widgets/mikrotik_router_image.dart';

void main() {
  testWidgets('late unknown technical model does not replace a local image', (
    tester,
  ) async {
    Future<void> show(String primary, List<String> alternatives) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MikrotikRouterImage(
              boardName: primary,
              alternativeModels: alternatives,
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
    }

    String asset() =>
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName;
    await show('', ['hAP ac²']);
    final original = asset();
    await show('unknown-technical-model', ['hAP ac²']);
    expect(asset(), original);
    // A different router must never retain the previous router's image.
    await show('RB951G-2HnD', []);
    expect(asset(), endsWith('mikrotik-routerboard-rb951g-2hnd.png'));
  });
  test('RouterBOARD and RB model spellings map to the same image', () {
    expect(
      MikrotikRouterImage.normalizeModel('RouterBOARD 951G-2HnD'),
      MikrotikRouterImage.normalizeModel('RB951G-2HnD'),
    );
    expect(
      MikrotikRouterImage.normalizeModel('hAP ac2'),
      MikrotikRouterImage.normalizeModel('hAP ac²'),
    );
    expect(MikrotikRouterImage.bestModel(['', 'RB951G-2HnD']), 'RB951G-2HnD');
  });
  test('similar hAP names never resolve through partial matching', () {
    expect(
      MikrotikRouterImage.normalizeModel('hAP ac'),
      isNot(MikrotikRouterImage.normalizeModel('hAP ac lite')),
    );
    expect(
      MikrotikRouterImage.normalizeModel('hAP ac lite'),
      isNot(MikrotikRouterImage.normalizeModel('hAP ac lite TC')),
    );
    expect(
      MikrotikRouterImage.normalizeModel('hAP lite'),
      isNot(MikrotikRouterImage.normalizeModel('hAP lite TC')),
    );
  });
  testWidgets('local WebP takes precedence over the remote catalogue', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MikrotikRouterImage(boardName: 'hAP ac²')),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'lib/assets/images-mikrotik/hAP ac².webp',
    );
  });
}
