import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';

class SalesCacheSnapshot {
  final List<Map<String, String>> rows;
  final DateTime? updatedAt;
  const SalesCacheSnapshot(this.rows, this.updatedAt);

  bool isFresh(DateTime now, Duration ttl) =>
      updatedAt != null && now.difference(updatedAt!) < ttl;
}

class SalesCacheRepository {
  const SalesCacheRepository();

  Future<SalesCacheSnapshot> read(int routerId) async {
    final db = await AppDatabase.instance.db;
    final result = await db.query(
      'sales_report_cache',
      where: 'router_id = ?',
      whereArgs: [routerId],
      limit: 1,
    );
    if (result.isEmpty) return const SalesCacheSnapshot([], null);
    try {
      final decoded = jsonDecode(result.first['payload'] as String);
      if (decoded is! List) throw const FormatException('Cache invalide');
      final rows = decoded
          .whereType<Map>()
          .map(
            (row) => row.map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            ),
          )
          .toList(growable: false);
      return SalesCacheSnapshot(
        rows,
        DateTime.tryParse('${result.first['updated_at']}'),
      );
    } catch (_) {
      await db.delete(
        'sales_report_cache',
        where: 'router_id = ?',
        whereArgs: [routerId],
      );
      return const SalesCacheSnapshot([], null);
    }
  }

  Future<void> replace(int routerId, List<Map<String, String>> rows) async {
    final immutable = rows
        .map((row) => Map<String, String>.unmodifiable({...row}))
        .toList(growable: false);
    final db = await AppDatabase.instance.db;
    await db.insert('sales_report_cache', {
      'router_id': routerId,
      'payload': jsonEncode(immutable),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
