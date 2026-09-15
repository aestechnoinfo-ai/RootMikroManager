import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/navigation/routes.dart';
import 'package:root_mikro_manager/core/theme/app_theme.dart';
import 'package:root_mikro_manager/shared/widgets/app_drawer.dart';

void main() {
  test('Routeurs appartient uniquement au groupe Application', () {
    expect(
      AppDrawer.winboxItems.any((item) => item.routeName == AppRoutes.routers),
      isFalse,
    );
    expect(
      AppDrawer.appItems.any((item) => item.routeName == AppRoutes.routers),
      isTrue,
    );
  });

  test('les réglages vouchers sont séparés des paramètres de application', () {
    expect(
      AppDrawer.appItems.any(
        (item) => item.routeName == AppRoutes.voucherTemplateEditor,
      ),
      isTrue,
    );
    expect(
      AppDrawer.appItems
          .firstWhere((item) => item.routeName == AppRoutes.settings)
          .label,
      'Paramètres de l’app',
    );
  });

  test('AppBar vert MikroTik et barre système transparente', () {
    expect(
      AppTheme.light.appBarTheme.backgroundColor,
      AppTheme.mikrotikLightGreen,
    );
    expect(AppTheme.light.appBarTheme.foregroundColor, AppTheme.mikrotikBlack);
    expect(
      AppTheme.light.appBarTheme.systemOverlayStyle?.statusBarColor,
      Colors.transparent,
    );
  });

  testWidgets('le drawer compact reste sans débordement sur téléphone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(drawer: AppDrawer(onSelect: (_) {})),
      ),
    );
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('ROOT M. M'), findsOneWidget);
    expect(find.text('Hotspot / R.M.M'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
