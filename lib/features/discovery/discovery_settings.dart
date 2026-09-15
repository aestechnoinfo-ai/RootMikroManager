import '../../core/database/app_database.dart';

class DiscoverySettings {
  final int scanTimeoutMs;
  final int scanConcurrency;
  final int maxHosts;
  final List<int> ports;
  final int retries;

  const DiscoverySettings({
    this.scanTimeoutMs = 15000,
    this.scanConcurrency = 32,
    this.maxHosts = 4096,
    this.ports = const [8728, 8729, 8291],
    this.retries = 5,
  });

  static Future<DiscoverySettings> load() async {
    final db = AppDatabase.instance;
    final timeoutRaw = await db.getSetting('scan_timeout_ms');
    final concurrencyRaw = await db.getSetting('discovery_scan_concurrency');
    final maxHostsRaw = await db.getSetting('discovery_scan_max_hosts');
    final portsRaw = await db.getSetting('discovery_scan_ports');
    final retriesRaw = await db.getSetting('discovery_scan_retries');

    int parse(String? value, int fallback, int min, int max) {
      return (int.tryParse(value ?? '') ?? fallback).clamp(min, max).toInt();
    }

    return DiscoverySettings(
      scanTimeoutMs: parse(timeoutRaw, 15000, 1000, 20000),
      scanConcurrency: parse(concurrencyRaw, 32, 1, 64),
      maxHosts: parse(maxHostsRaw, 4096, 32, 65534),
      ports: portsRaw == null
          ? const [8728, 8729, 8291]
          : portsRaw
                .split(',')
                .map((value) => int.tryParse(value.trim()))
                .whereType<int>()
                .where((port) => port > 0 && port <= 65535)
                .toSet()
                .toList(),
      retries: parse(retriesRaw, 5, 1, 5),
    );
  }

  Future<void> save() async {
    final db = AppDatabase.instance;
    await db.setSetting('scan_timeout_ms', '$scanTimeoutMs');
    await db.setSetting('discovery_scan_concurrency', '$scanConcurrency');
    await db.setSetting('discovery_scan_max_hosts', '$maxHosts');
    await db.setSetting('discovery_scan_ports', ports.join(','));
    await db.setSetting('discovery_scan_retries', '$retries');
  }
}
