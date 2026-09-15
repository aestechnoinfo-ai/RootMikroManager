import '../../core/routeros/routeros_service.dart';
import '../../core/routeros/routeros_client.dart';
import 'dashboard_settings.dart';
import 'dashboard_snapshot.dart';

class DashboardDataService {
  final RouterOsService service;

  DashboardDataService(
    this.service, {
    Future<List<Map<String, String>>> Function()? salesReader,
    DateTime Function()? now,
  }) : _salesReader = salesReader ?? service.salesSummaryRows,
       _now = now ?? DateTime.now;
  final Future<List<Map<String, String>>> Function() _salesReader;
  final DateTime Function() _now;
  DateTime? _salesAttempt;
  static const salesRefreshInterval = Duration(seconds: 60);
  final _values = <String, dynamic>{};
  final errors = <String, String>{};
  final pending = <String>{};
  bool hasData(String section) => _values.containsKey(section);

  Future<DashboardSnapshot> load(
    DashboardSettings settings, {
    void Function(DashboardSnapshot)? onUpdate,
    bool Function()? cancelled,
    bool forceSales = false,
  }) async {
    final shouldReadSales =
        forceSales ||
        _salesAttempt == null ||
        _now().difference(_salesAttempt!) >= salesRefreshInterval;

    // Lightweight system information first. Sales is deliberately read before
    // optional RouterOS collections: in production this reader is SQLite-only,
    // so a later network interruption must not hide the last healthy totals.
    // Do not queue ten commands at once on the serialized API socket.
    final readers = <String, Future<dynamic> Function()>{
      'resource': service.resource,
      'identity': service.identity,
      'clock': service.systemClock,
      if (shouldReadSales)
        'sales': () {
          _salesAttempt = _now();
          return _salesReader();
        },
      'routerboard': () => service.client.first('/system/routerboard'),
      'logs': service.logs,
      'interfaces': service.interfaces,
      'hotspot': service.activeUsers,
      'ppp': service.pppActive,
      'tickets': service.hotspotUsersDashboardSummary,
    };
    pending
      ..clear()
      ..addAll(readers.keys);
    for (final key in readers.keys) {
      errors.remove(key);
    }
    for (final entry in readers.entries) {
      if (cancelled?.call() ?? false) break;
      try {
        final value = await entry.value();
        if (cancelled?.call() ?? false) break;
        _values[entry.key] = value;
      } catch (error) {
        errors[entry.key] = error is RouterOsException
            ? error.message
            : 'Lecture impossible (${error.runtimeType})';
        // A permission trap affects one section. A lost transport stops the
        // cycle instead of reconnecting once per remaining section.
        if (!service.isConnected) {
          for (final key in pending) {
            errors.putIfAbsent(
              key,
              () => 'Non chargé après interruption de connexion',
            );
          }
          pending.clear();
          onUpdate?.call(_snapshot(settings));
          break;
        }
      }
      pending.remove(entry.key);
      onUpdate?.call(_snapshot(settings));
    }
    pending.clear();
    return _snapshot(settings);
  }

  DashboardSnapshot _snapshot(DashboardSettings settings) {
    Map<String, String> row(String key) =>
        _values[key] as Map<String, String>? ?? <String, String>{};
    List<Map<String, String>> rows(String key) =>
        _values[key] as List<Map<String, String>>? ?? <Map<String, String>>[];
    return DashboardSnapshot.fromRaw(
      identity: row('identity'),
      resource: row('resource'),
      clock: row('clock'),
      routerboard: row('routerboard'),
      hotspotActive: rows('hotspot'),
      pppActive: rows('ppp'),
      hotspotUsers: rows('tickets'),
      salesRows: rows('sales'),
      logs: rows('logs').take(settings.logCount).toList(),
      interfaces: rows('interfaces'),
      now:
          DashboardSnapshot.parseReportDate(
            row('clock')['date'] ?? '',
            fallbackYear: DateTime.now().year,
          ) ??
          DateTime.now(),
    );
  }

  String chooseTrafficInterface(
    DashboardSnapshot snapshot,
    DashboardSettings settings,
  ) {
    final configured = settings.trafficInterface.trim();
    if (configured.isNotEmpty) return configured;

    Map<String, String>? firstRunning;
    for (final row in snapshot.interfaces) {
      final name = row['name'] ?? '';
      final running = row['running'] == 'true' || row['running'] == 'yes';
      final disabled = row['disabled'] == 'true' || row['disabled'] == 'yes';
      if (name.isEmpty || disabled || name == 'lo') continue;
      if (running) {
        firstRunning = row;
        break;
      }
    }

    return firstRunning?['name'] ??
        (snapshot.interfaces.isEmpty
            ? ''
            : snapshot.interfaces.first['name'] ?? '');
  }
}
