import 'package:sqflite/sqflite.dart';

class VoucherHistoryRepository {
  final Database db;
  const VoucherHistoryRepository(this.db);

  Future<List<Map<String, Object?>>> read(
    int? routerId, {
    int? limit,
    String? username,
  }) {
    if (routerId == null) return Future.value(const []);
    return db.query(
      'voucher_history',
      where: username == null
          ? 'router_id = ?'
          : 'router_id = ? AND username = ?',
      whereArgs: username == null ? [routerId] : [routerId, username],
      orderBy: 'id DESC',
      limit: limit,
    );
  }

  Future<int> count(int? routerId) async {
    if (routerId == null) return 0;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM voucher_history WHERE router_id = ?',
      [routerId],
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> clear(int? routerId) => routerId == null
      ? Future.value(0)
      : db.delete(
          'voucher_history',
          where: 'router_id = ?',
          whereArgs: [routerId],
        );
}
