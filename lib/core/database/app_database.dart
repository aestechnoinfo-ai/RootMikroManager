import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    return _db ??= await openDatabase(
      join(await getDatabasesPath(), 'root_mikro_manager.db'),
      version: 10,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
  }

  Future<Database> get database => db;

  Future<void> _create(Database database, int version) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS routers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL,
        username TEXT NOT NULL,
        group_name TEXT NOT NULL DEFAULT 'Général',
        tags TEXT NOT NULL DEFAULT '',
        color_value INTEGER,
        created_at TEXT NOT NULL,
        mac_address TEXT NOT NULL DEFAULT '',
        romon_id TEXT NOT NULL DEFAULT '',
        use_tls INTEGER NOT NULL DEFAULT 0,
        protocols TEXT NOT NULL DEFAULT '',
        board_name TEXT NOT NULL DEFAULT ''
      )
    ''');

    await _createExtra(database);
  }

  Future<void> _upgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    // Always reconcile auxiliary tables with their expected schema. Some
    // early databases reached version 2+ without the later voucher columns,
    // so relying only on the stored version leaves them permanently broken.
    await _createExtra(database);

    if (oldVersion < 3) {
      final columns = await database.rawQuery('PRAGMA table_info(routers)');
      if (!columns.any((row) => row['name'] == 'created_at')) {
        await database.execute(
          'ALTER TABLE routers ADD COLUMN created_at TEXT',
        );
        await database.execute(
          "UPDATE routers SET created_at = datetime('now') "
          "WHERE created_at IS NULL",
        );
      }
    }

    if (oldVersion < 4) {
      final columns = await database.rawQuery('PRAGMA table_info(routers)');
      final names = columns.map((row) => row['name']).toSet();

      if (!names.contains('group_name')) {
        await database.execute(
          "ALTER TABLE routers ADD COLUMN group_name TEXT "
          "NOT NULL DEFAULT 'Général'",
        );
      }

      if (!names.contains('tags')) {
        await database.execute(
          "ALTER TABLE routers ADD COLUMN tags TEXT "
          "NOT NULL DEFAULT ''",
        );
      }

      if (!names.contains('color_value')) {
        await database.execute(
          'ALTER TABLE routers ADD COLUMN color_value INTEGER',
        );
      }
    }

    if (oldVersion < 6) {
      final columns = await database.rawQuery('PRAGMA table_info(routers)');
      final names = columns.map((row) => row['name']).toSet();
      if (!names.contains('mac_address')) {
        await database.execute(
          "ALTER TABLE routers ADD COLUMN mac_address TEXT NOT NULL DEFAULT ''",
        );
      }
      if (!names.contains('romon_id')) {
        await database.execute(
          "ALTER TABLE routers ADD COLUMN romon_id TEXT NOT NULL DEFAULT ''",
        );
      }
      if (!names.contains('use_tls')) {
        await database.execute(
          'ALTER TABLE routers ADD COLUMN use_tls INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!names.contains('protocols')) {
        await database.execute(
          "ALTER TABLE routers ADD COLUMN protocols TEXT NOT NULL DEFAULT ''",
        );
      }
    }

    if (oldVersion < 7) {
      final columns = await database.rawQuery('PRAGMA table_info(routers)');
      final names = columns.map((row) => row['name']).toSet();
      if (!names.contains('board_name')) {
        await database.execute(
          "ALTER TABLE routers ADD COLUMN board_name TEXT NOT NULL DEFAULT ''",
        );
      }
    }
  }

  Future<void> _createExtra(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS voucher_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        router_id INTEGER,
        username TEXT,
        password TEXT,
        profile TEXT,
        selling_price TEXT,
        validity TEXT,
        comment TEXT NOT NULL DEFAULT '',
        hotspot_name TEXT NOT NULL DEFAULT '',
        created_at TEXT
      )
    ''');

    await _ensureVoucherHistoryColumns(database);

    await database.execute('''
      CREATE TABLE IF NOT EXISTS activity_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        router_id INTEGER,
        action TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE IF NOT EXISTS app_settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await database.execute('''
      CREATE TABLE IF NOT EXISTS sales_report_cache(
        router_id INTEGER PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureVoucherHistoryColumns(Database database) async {
    final info = await database.rawQuery('PRAGMA table_info(voucher_history)');
    final names = info.map((row) => row['name']).toSet();
    if (!names.contains('selling_price')) {
      await database.execute(
        'ALTER TABLE voucher_history ADD COLUMN selling_price TEXT',
      );
    }
    if (!names.contains('validity')) {
      await database.execute(
        'ALTER TABLE voucher_history ADD COLUMN validity TEXT',
      );
    }
    if (!names.contains('comment')) {
      await database.execute(
        "ALTER TABLE voucher_history ADD COLUMN comment TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!names.contains('hotspot_name')) {
      await database.execute(
        "ALTER TABLE voucher_history ADD COLUMN hotspot_name TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  Future<void> log(
    String action, {
    int? routerId,
    Map<String, dynamic>? data,
  }) async {
    final database = await db;

    await database.insert('activity_logs', {
      'router_id': routerId,
      'action': action,
      'data': jsonEncode(data ?? {}),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> logs({int limit = 300}) async {
    final database = await db;

    return database.query('activity_logs', orderBy: 'id DESC', limit: limit);
  }

  Future<void> clearLogs() async {
    final database = await db;
    await database.delete('activity_logs');
  }

  Future<void> setSetting(String key, String value) async {
    final database = await db;

    await database.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final database = await db;
    final rows = await database.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first['value']?.toString();
  }

  Future<Map<String, dynamic>> exportJson() async {
    final database = await db;

    return {
      'format': 'RootMikroManager',
      'schema_version': 6,
      'exported_at': DateTime.now().toIso8601String(),
      'routers': await database.query('routers'),
      'voucher_history': await database.query('voucher_history'),
      'activity_logs': await database.query('activity_logs'),
      'app_settings': await database.query('app_settings'),
    };
  }

  Future<void> importJson(
    Map<String, dynamic> backup, {
    bool replaceExisting = false,
  }) async {
    if (backup['format'] != null && backup['format'] != 'RootMikroManager') {
      throw const FormatException(
        'Format de sauvegarde RootMikroManager non reconnu.',
      );
    }

    final database = await db;

    await database.transaction((txn) async {
      if (replaceExisting) {
        await txn.delete('routers');
        await txn.delete('voucher_history');
        await txn.delete('activity_logs');
        await txn.delete('app_settings');
      }

      for (final table in [
        'routers',
        'voucher_history',
        'activity_logs',
        'app_settings',
      ]) {
        final rows = backup[table];
        if (rows is! List) continue;

        for (final raw in rows) {
          if (raw is! Map) continue;

          await txn.insert(
            table,
            Map<String, dynamic>.from(raw),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }
}
