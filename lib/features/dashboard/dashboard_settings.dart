import '../../core/database/app_database.dart';

class DashboardSettings {
  final bool autoRefresh;
  final int refreshSeconds;
  final int trafficRefreshSeconds;
  final int trafficWindowSeconds;
  final int logCount;
  final int warningPercent;
  final int criticalPercent;
  final int ticketWarningCount;
  final int ticketCriticalCount;
  final String trafficInterface;

  const DashboardSettings({
    this.autoRefresh = true,
    this.refreshSeconds = 10,
    this.trafficRefreshSeconds = 2,
    this.trafficWindowSeconds = 60,
    this.logCount = 5,
    this.warningPercent = 70,
    this.criticalPercent = 90,
    this.ticketWarningCount = 20,
    this.ticketCriticalCount = 5,
    this.trafficInterface = '',
  });

  static Future<DashboardSettings> load() async {
    final db = AppDatabase.instance;

    int number(String? value, int fallback, int min, int max) {
      final parsed = int.tryParse(value ?? '') ?? fallback;
      return parsed.clamp(min, max).toInt();
    }

    final warning = number(
      await db.getSetting('dashboard_warning_percent'),
      70,
      1,
      98,
    );
    final critical = number(
      await db.getSetting('dashboard_critical_percent'),
      90,
      warning + 1,
      99,
    );

    return DashboardSettings(
      autoRefresh: (await db.getSetting('auto_refresh')) != 'false',
      refreshSeconds: number(
        await db.getSetting('dashboard_refresh_seconds'),
        10,
        3,
        300,
      ),
      trafficRefreshSeconds: number(
        await db.getSetting('dashboard_traffic_refresh_seconds'),
        2,
        1,
        30,
      ),
      trafficWindowSeconds: number(
        await db.getSetting('dashboard_traffic_window_seconds'),
        60,
        10,
        600,
      ),
      logCount: number(await db.getSetting('dashboard_log_count'), 5, 1, 50),
      warningPercent: warning,
      criticalPercent: critical,
      ticketWarningCount: number(
        await db.getSetting('dashboard_ticket_warning_count'),
        20,
        1,
        100000,
      ),
      ticketCriticalCount: number(
        await db.getSetting('dashboard_ticket_critical_count'),
        5,
        0,
        99999,
      ),
      trafficInterface:
          await db.getSetting('dashboard_traffic_interface') ?? '',
    );
  }

  Future<void> save() async {
    final db = AppDatabase.instance;
    await db.setSetting('auto_refresh', '$autoRefresh');
    await db.setSetting('dashboard_refresh_seconds', '$refreshSeconds');
    await db.setSetting(
      'dashboard_traffic_refresh_seconds',
      '$trafficRefreshSeconds',
    );
    await db.setSetting(
      'dashboard_traffic_window_seconds',
      '$trafficWindowSeconds',
    );
    await db.setSetting('dashboard_log_count', '$logCount');
    await db.setSetting('dashboard_warning_percent', '$warningPercent');
    await db.setSetting('dashboard_critical_percent', '$criticalPercent');
    await db.setSetting(
      'dashboard_ticket_warning_count',
      '$ticketWarningCount',
    );
    await db.setSetting(
      'dashboard_ticket_critical_count',
      '$ticketCriticalCount',
    );
    await db.setSetting('dashboard_traffic_interface', trafficInterface.trim());
  }
}
