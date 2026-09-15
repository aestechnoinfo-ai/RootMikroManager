import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_history_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('les historiques de deux routeurs ne se mélangent jamais', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('''
      CREATE TABLE voucher_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        router_id INTEGER,
        username TEXT,
        profile TEXT
      )
    ''');
    await db.insert('voucher_history', {
      'router_id': 1,
      'username': 'ticket-routeur-1',
      'profile': 'profil-routeur-1',
    });
    await db.insert('voucher_history', {
      'router_id': 2,
      'username': 'ticket-routeur-2',
      'profile': 'profil-routeur-2',
    });
    await db.insert('voucher_history', {
      'router_id': null,
      'username': 'ancien-ticket-sans-routeur',
      'profile': 'ancien-profil',
    });

    final repository = VoucherHistoryRepository(db);
    final router1 = await repository.read(1);
    final router2 = await repository.read(2);

    expect(router1.map((row) => row['username']), ['ticket-routeur-1']);
    expect(router2.map((row) => row['username']), ['ticket-routeur-2']);

    await repository.clear(1);
    expect(await repository.read(1), isEmpty);
    expect((await repository.read(2)).single['username'], 'ticket-routeur-2');
  });
}
