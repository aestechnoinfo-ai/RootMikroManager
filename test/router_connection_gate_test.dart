import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/network/ip_scanner_service.dart';
import 'package:root_mikro_manager/data/models/router_model.dart';
import 'package:root_mikro_manager/features/routers/router_connection_screen.dart';

class FakeScanner extends IpScannerService {
  bool online = true;
  @override
  Future<ScannedHost> probeHost(String host, int port, {
    Duration timeout = const Duration(seconds: 15),
    int retries = 5,
    CancellationToken? cancellationToken,
  }) async => ScannedHost(ip: host, openPorts: online ? [port] : [],
      status: online ? ScanHostStatus.online : ScanHostStatus.offline);
}

void main() {
  testWidgets('Connecter requires a successful ping and relocks after failure', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final scanner = FakeScanner();
    await tester.pumpWidget(MaterialApp(home: RouterConnectionScreen(
      router: const RouterModel(id: 1, name: 'Test', host: '192.0.2.1',
          port: 9000, username: 'custom'), scanner: scanner,
    )));
    await tester.pumpAndSettle();
    final connect = find.widgetWithText(FilledButton, 'Connecter');
    expect(tester.widget<FilledButton>(connect).onPressed, isNull);
    await tester.tap(find.text('Pinger'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(connect).onPressed, isNotNull);
    scanner.online = false;
    await tester.tap(find.text('Pinger'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(connect).onPressed, isNull);
  });
}
