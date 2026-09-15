import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/database/app_database.dart';

class AppBackupFile {
  final String path;
  final String name;
  final DateTime modifiedAt;
  final int size;

  const AppBackupFile({
    required this.path,
    required this.name,
    required this.modifiedAt,
    required this.size,
  });
}

class AppBackupService {
  static const _prefix = 'RootMikroManager_backup_';

  Future<Directory> backupDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/backups');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<AppBackupFile> create() async {
    final data = await AppDatabase.instance.exportJson();
    final dir = await backupDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${dir.path}/$_prefix$stamp.json');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );

    final stat = await file.stat();
    await AppDatabase.instance.log(
      'app.backup.created',
      data: {'file': file.path, 'size': stat.size},
    );

    return AppBackupFile(
      path: file.path,
      name: file.uri.pathSegments.last,
      modifiedAt: stat.modified,
      size: stat.size,
    );
  }

  Future<List<AppBackupFile>> list() async {
    final dir = await backupDirectory();
    final items = <AppBackupFile>[];

    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      final stat = await entity.stat();
      items.add(
        AppBackupFile(
          path: entity.path,
          name: entity.uri.pathSegments.last,
          modifiedAt: stat.modified,
          size: stat.size,
        ),
      );
    }

    items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items;
  }

  Future<String> read(AppBackupFile backup) => File(backup.path).readAsString();

  Future<void> restore(
    AppBackupFile backup, {
    required bool replaceExisting,
  }) async {
    final decoded = jsonDecode(await read(backup));
    if (decoded is! Map) {
      throw const FormatException('Sauvegarde JSON invalide.');
    }

    await AppDatabase.instance.importJson(
      Map<String, dynamic>.from(decoded),
      replaceExisting: replaceExisting,
    );

    await AppDatabase.instance.log(
      'app.backup.restored',
      data: {'file': backup.path, 'replace_existing': replaceExisting},
    );
  }

  Future<void> delete(AppBackupFile backup) async {
    final file = File(backup.path);
    if (await file.exists()) await file.delete();

    await AppDatabase.instance.log(
      'app.backup.deleted',
      data: {'file': backup.path},
    );
  }
}
