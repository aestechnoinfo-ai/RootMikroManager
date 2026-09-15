import '../../core/database/app_database.dart';

class PppMonitorSettings {
  final bool autoRefresh;
  final int refreshSeconds;
  final bool confirmDisconnect;
  const PppMonitorSettings({
    this.autoRefresh = true,
    this.refreshSeconds = 5,
    this.confirmDisconnect = true,
  });

  static Future<PppMonitorSettings> load() async {
    final db = AppDatabase.instance;
    final seconds =
        (int.tryParse(
                  await db.getSetting('ppp_active_refresh_seconds') ?? '',
                ) ??
                5)
            .clamp(2, 300)
            .toInt();
    return PppMonitorSettings(
      autoRefresh: (await db.getSetting('ppp_active_auto_refresh')) != 'false',
      refreshSeconds: seconds,
      confirmDisconnect:
          (await db.getSetting('ppp_confirm_disconnect')) != 'false',
    );
  }

  Future<void> save() async {
    final db = AppDatabase.instance;
    await db.setSetting('ppp_active_auto_refresh', '$autoRefresh');
    await db.setSetting('ppp_active_refresh_seconds', '$refreshSeconds');
    await db.setSetting('ppp_confirm_disconnect', '$confirmDisconnect');
  }
}
