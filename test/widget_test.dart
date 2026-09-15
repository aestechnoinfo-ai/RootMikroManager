// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:root_mikro_manager/app.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('L’application démarre sur le tableau de bord',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RootMikroManagerApp());
    await tester.pump();

    expect(find.text('RootMikroManager'), findsWidgets);
    // Exercise the bounded local-settings bootstrap with fake time.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
  });
}
