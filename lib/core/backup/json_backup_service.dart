import 'dart:convert';
import '../database/app_database.dart';
import '../export/user_selected_export_service.dart';

class JsonBackupService {
  Future<String?> exportBackup() async {
    final data = await AppDatabase.instance.exportJson();
    return const UserSelectedExportService().saveText(
      suggestedName: 'rootmikromanager_backup.json',
      mimeType: 'application/json',
      content: const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  Future<void> importBackup(String content) async {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>)
      throw const FormatException('Backup JSON invalide');
    await AppDatabase.instance.importJson(decoded);
  }
}
