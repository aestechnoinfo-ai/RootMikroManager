import '../../core/database/app_database.dart';

class VoucherReprintAuditService {
  const VoucherReprintAuditService();

  Future<void> record({
    required String username,
    required String profile,
    required String layout,
    int? routerId,
  }) async {
    await AppDatabase.instance.log(
      'voucher.reprinted',
      routerId: routerId,
      data: {
        'username': username,
        'profile': profile,
        'layout': layout,
        'sale_created': false,
      },
    );
  }
}
