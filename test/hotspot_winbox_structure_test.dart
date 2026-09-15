import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/navigation/routes.dart';
import 'package:root_mikro_manager/features/hotspot/hotspot_winbox_screen.dart';
import 'package:root_mikro_manager/shared/widgets/app_drawer.dart';

void main() {
  test('les entrées Hotspot RMM et WinBox utilisent des routes distinctes', () {
    final rmm = AppDrawer.mikhmonItems.firstWhere(
      (item) => item.label == 'Hotspot',
    );
    final winbox = AppDrawer.winboxItems.firstWhere(
      (item) => item.label == 'Hotspot (WinBox)',
    );
    expect(rmm.routeName, AppRoutes.hotspot);
    expect(winbox.routeName, AppRoutes.hotspotWinbox);
    expect(winbox.routeName, isNot(rmm.routeName));
  });

  testWidgets('le hub WinBox expose les objets RouterOS essentiels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HotspotWinboxScreen()));

    for (final label in ['Hotspot Setup', 'Servers', 'Server Profiles']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    for (final label in [
      'Users',
      'User Profiles',
      'Active · Hosts · Cookies · IP Bindings',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
