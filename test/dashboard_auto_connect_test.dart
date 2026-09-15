import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:root_mikro_manager/core/routeros/router_session.dart';
import 'package:root_mikro_manager/data/models/router_model.dart';
import 'package:root_mikro_manager/features/dashboard/dashboard_screen.dart';
import 'package:root_mikro_manager/features/dashboard/dashboard_data_service.dart';
import 'dashboard_loading_test.dart' show FakeDashboardRouter;

void main() {
  testWidgets('mounted dashboard loads on connection without refresh tap', (
    tester,
  ) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final session = RouterSession.instance;
    final fake = FakeDashboardRouter();
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          loaderFactory: () => DashboardDataService(fake),
          ensureConnection: () async {},
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    expect(fake.calls, isEmpty);
    session.registerActiveRouter(
      RouterModel(name: 'Mock', host: '192.0.2.1', port: 8728, username: 'admin'),
      'test',
    );
    await tester.pump();
    await tester.pump();
    expect(fake.calls, contains('resource'));
    expect(fake.calls, contains('sales'));
    expect(fake.calls, contains('logs'));
    await tester.pumpWidget(const SizedBox());
    await session.disconnect();
  });
}
