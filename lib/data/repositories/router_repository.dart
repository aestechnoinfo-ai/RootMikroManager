import '../../core/database/app_database.dart';
import '../models/router_model.dart';

class RouterRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<void> updateBoardName(int id, String boardName) async {
    if (boardName.trim().isEmpty) return;
    final database = await _db.db;
    await database.update(
      'routers',
      {'board_name': boardName.trim()},
      where: 'id = ? AND board_name <> ?',
      whereArgs: [id, boardName.trim()],
    );
  }

  Future<List<RouterModel>> all({String? search, String? group}) async {
    final database = await _db.db;
    final rows = await database.query(
      'routers',
      orderBy: 'group_name COLLATE NOCASE, name COLLATE NOCASE',
    );

    var list = rows.map(RouterModel.fromMap).toList();

    if (group != null && group.isNotEmpty && group != 'Tous') {
      list = list.where((r) => r.groupName == group).toList();
    }

    final query = search?.trim().toLowerCase() ?? '';
    if (query.isNotEmpty) {
      list = list.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.host.toLowerCase().contains(query) ||
            r.username.toLowerCase().contains(query) ||
            r.groupName.toLowerCase().contains(query) ||
            r.tags.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  Future<List<String>> groups() async {
    final database = await _db.db;
    final rows = await database.rawQuery(
      "SELECT DISTINCT group_name FROM routers "
      "ORDER BY group_name COLLATE NOCASE",
    );

    return [
      'Tous',
      ...rows
          .map((e) => e['group_name']?.toString() ?? '')
          .where((e) => e.isNotEmpty),
    ];
  }

  Future<int> save(RouterModel router) async {
    final database = await _db.db;
    final map = router.toMap()..remove('id');

    final mac = router.macAddress.trim().toUpperCase();
    final romon = router.romonId.trim().toUpperCase();
    map['mac_address'] = mac;
    map['romon_id'] = romon;
    final id = await database.transaction((txn) async {
      if (mac.isNotEmpty || romon.isNotEmpty) {
        final existing = await txn.query(
          'routers',
          columns: ['id'],
          where:
              "(? <> '' AND UPPER(TRIM(mac_address)) = ?) OR "
              "(? <> '' AND UPPER(TRIM(romon_id)) = ?)",
          whereArgs: [mac, mac, romon, romon],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          throw StateError(
            'Équipement déjà enregistré. Modifiez sa fiche existante.',
          );
        }
      }
      return txn.insert('routers', map);
    });

    await _db.log(
      'router.created',
      routerId: id,
      data: {'name': router.name, 'host': router.host},
    );

    return id;
  }

  Future<void> update(RouterModel router) async {
    if (router.id == null) return;

    final database = await _db.db;
    final map = router.toMap()
      ..remove('id')
      ..remove('created_at');

    await database.update(
      'routers',
      map,
      where: 'id = ?',
      whereArgs: [router.id],
    );

    await _db.log(
      'router.updated',
      routerId: router.id,
      data: {'name': router.name, 'host': router.host},
    );
  }

  Future<void> remove(int id) async {
    final database = await _db.db;

    final old = await database.query(
      'routers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    await database.delete('routers', where: 'id = ?', whereArgs: [id]);

    await _db.log(
      'router.deleted',
      routerId: id,
      data: old.isEmpty ? {} : Map<String, dynamic>.from(old.first),
    );
  }
}
