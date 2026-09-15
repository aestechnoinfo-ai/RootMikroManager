import '../../core/database/app_database.dart';

class HotspotMonitorSettings {
  final bool autoRefresh;
  final int refreshSeconds;
  final bool showTraffic;
  final bool confirmDisconnect;

  const HotspotMonitorSettings({
    this.autoRefresh = true,
    this.refreshSeconds = 5,
    this.showTraffic = true,
    this.confirmDisconnect = true,
  });

  static Future<HotspotMonitorSettings> load() async {
    final db = AppDatabase.instance;
    int parse(String? v, int fallback) =>
        (int.tryParse(v ?? '') ?? fallback).clamp(2, 300).toInt();

    return HotspotMonitorSettings(
      autoRefresh:
          (await db.getSetting('hotspot_active_auto_refresh')) != 'false',
      refreshSeconds: parse(
        await db.getSetting('hotspot_active_refresh_seconds'),
        5,
      ),
      showTraffic:
          (await db.getSetting('hotspot_active_show_traffic')) != 'false',
      confirmDisconnect:
          (await db.getSetting('hotspot_active_confirm_disconnect')) != 'false',
    );
  }

  Future<void> save() async {
    final db = AppDatabase.instance;
    await db.setSetting('hotspot_active_auto_refresh', '$autoRefresh');
    await db.setSetting('hotspot_active_refresh_seconds', '$refreshSeconds');
    await db.setSetting('hotspot_active_show_traffic', '$showTraffic');
    await db.setSetting(
      'hotspot_active_confirm_disconnect',
      '$confirmDisconnect',
    );
  }
}
