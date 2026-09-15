import 'rootmikromanager_sales_record.dart';

class SalesRecordIdentity {
  const SalesRecordIdentity();

  String strictKey(RootMikroManagerSalesRecord record) => [
    record.date.trim(),
    record.time.trim(),
    record.username.trim(),
    record.price.trim(),
    record.profile.trim(),
  ].join('\u0000');
}
