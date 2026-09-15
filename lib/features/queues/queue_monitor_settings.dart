import '../../core/database/app_database.dart';

class QueueMonitorSettings {
  final bool autoRefresh;
  final int refreshSeconds;
  final bool showBytes;
  final bool showPackets;

  const QueueMonitorSettings({
    this.autoRefresh = true,
    this.refreshSeconds = 3,
    this.showBytes = true,
    this.showPackets = true,
  });

  static Future<QueueMonitorSettings> load() async {
    final db = AppDatabase.instance;
    final seconds =
        (int.tryParse(
                  await db.getSetting('queue_monitor_refresh_seconds') ?? '',
                ) ??
                3)
            .clamp(1, 300)
            .toInt();

    return QueueMonitorSettings(
      autoRefresh:
          (await db.getSetting('queue_monitor_auto_refresh')) != 'false',
      refreshSeconds: seconds,
      showBytes: (await db.getSetting('queue_monitor_show_bytes')) != 'false',
      showPackets:
          (await db.getSetting('queue_monitor_show_packets')) != 'false',
    );
  }

  Future<void> save() async {
    final db = AppDatabase.instance;
    await db.setSetting('queue_monitor_auto_refresh', '$autoRefresh');
    await db.setSetting('queue_monitor_refresh_seconds', '$refreshSeconds');
    await db.setSetting('queue_monitor_show_bytes', '$showBytes');
    await db.setSetting('queue_monitor_show_packets', '$showPackets');
  }
}
