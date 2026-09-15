import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/routeros/routeros_service.dart';
import 'package:root_mikro_manager/core/routeros/routeros_client.dart';
import 'package:root_mikro_manager/features/dashboard/dashboard_data_service.dart';
import 'package:root_mikro_manager/features/dashboard/dashboard_settings.dart';

class FakeDashboardRouter extends RouterOsService {
  bool failSales = false;
  bool live = true;
  List<Map<String, String>> ticketSummary = const [];
  final calls = <String>[];
  @override
  bool get isConnected => live;
  @override
  Future<Map<String, String>> resource() async {
    calls.add('resource');
    return {'cpu-load': '12'};
  }

  @override
  Future<Map<String, String>> identity() async => {'name': 'Mock'};
  @override
  Future<Map<String, String>> systemClock() async => {'date': '2026-09-04'};
  @override
  Future<List<Map<String, String>>> interfaces() async => [
    {'name': 'ether1', 'running': 'true'},
  ];
  @override
  Future<List<Map<String, String>>> activeUsers({String? server}) async => [];
  @override
  Future<List<Map<String, String>>> pppActive() async => [];
  @override
  Future<List<Map<String, String>>> hotspotUsersDashboardSummary() async =>
      ticketSummary;
  @override
  Future<List<Map<String, String>>> salesSummaryRows() async {
    calls.add('sales');
    if (failSales) throw StateError('permission denied');
    return [];
  }

  @override
  Future<List<Map<String, String>>> logs() async {
    calls.add('logs');
    return [
      {'message': 'ok'},
    ];
  }
}

void main() {
  test('dashboard accepts a constant-size counter for 50000 users', () async {
    final router = FakeDashboardRouter()
      ..ticketSummary = [
        {'profile': 'Tous les profils', 'dashboard-count': '50000'},
      ];
    final loader = DashboardDataService(router);
    final snapshot = await loader.load(const DashboardSettings());
    expect(snapshot.remainingTicketsTotal, 50000);
    expect(snapshot.remainingTicketsByProfile['Tous les profils'], 50000);
  });
  test(
    'sales timeout leaves core sections available and respects cooldown',
    () async {
      final router = FakeDashboardRouter();
      var now = DateTime(2026, 9, 4);
      var attempts = 0;
      final loader = DashboardDataService(
        router,
        now: () => now,
        salesReader: () async {
          attempts++;
          throw RouterOsException('Délai de réponse RouterOS dépassé');
        },
      );
      final data = await loader.load(const DashboardSettings());
      expect(data.logs.single['message'], 'ok');
      for (final section in ['interfaces', 'hotspot', 'ppp', 'tickets']) {
        expect(loader.hasData(section), isTrue);
        expect(loader.errors.containsKey(section), isFalse);
      }
      expect(router.isConnected, isTrue);
      expect(loader.errors['sales'], contains('Délai'));
      await loader.load(const DashboardSettings());
      expect(attempts, 1);
      expect(loader.errors['sales'], contains('Délai'));
      now = now.add(const Duration(seconds: 61));
      await loader.load(const DashboardSettings());
      expect(attempts, 2);
      await loader.load(const DashboardSettings(), forceSales: true);
      expect(attempts, 3);
    },
  );
  test(
    'publishes resource before slow optional sections; errors are isolated',
    () async {
      final router = FakeDashboardRouter()..failSales = true;
      final loader = DashboardDataService(router);
      var updates = 0;
      final result = await loader.load(
        const DashboardSettings(),
        onUpdate: (snapshot) {
          if (updates++ == 0) {
            expect(snapshot.resource['cpu-load'], '12');
            expect(router.calls, ['resource']);
            expect(loader.pending, contains('sales'));
            expect(loader.hasData('sales'), isFalse);
          }
        },
      );
      expect(result.identity['name'], 'Mock');
      expect(result.logs.single['message'], 'ok');
      expect(loader.errors, contains('sales'));
      expect(loader.hasData('sales'), isFalse);
      expect(loader.pending, isEmpty);
    },
  );
  test(
    'retains previous successful section and marks failed refresh',
    () async {
      final router = FakeDashboardRouter();
      final loader = DashboardDataService(router);
      await loader.load(const DashboardSettings());
      router.failSales = true;
      await loader.load(const DashboardSettings(), forceSales: true);
      expect(loader.hasData('sales'), isTrue);
      expect(loader.errors, contains('sales'));
    },
  );
  test('cancelled screen does not submit remaining commands', () async {
    final router = FakeDashboardRouter();
    final loader = DashboardDataService(router);
    var cancelled = false;
    await loader.load(
      const DashboardSettings(),
      cancelled: () => cancelled,
      onUpdate: (_) => cancelled = true,
    );
    expect(router.calls, ['resource']);
    expect(loader.hasData('identity'), isFalse);
  });
  test('transport loss stops cycle instead of retrying each section', () async {
    final router = FakeDashboardRouter()..live = false;
    final loader = DashboardDataService(router);
    // Routerboard uses a disconnected mock client and fails without networking.
    await loader.load(const DashboardSettings());
    // The cache-backed sales reader runs before the optional network sections,
    // even when the RouterOS transport is already unavailable.
    expect(router.calls, ['resource', 'sales']);
    expect(loader.hasData('sales'), isTrue);
    expect(loader.errors, isNot(contains('sales')));
    expect(loader.pending, isEmpty);
  });
}
