import '../reports/rootmikromanager_sales_record.dart';
import '../reports/sales_record_identity.dart';

class VoucherSalesLedgerEntry {
  final String username;
  final String profile;
  final double amount;
  final String date;
  final String time;
  final bool duplicate;

  const VoucherSalesLedgerEntry({
    required this.username,
    required this.profile,
    required this.amount,
    required this.date,
    required this.time,
    required this.duplicate,
  });
}

class VoucherSalesLedgerService {
  const VoucherSalesLedgerService();

  List<VoucherSalesLedgerEntry> normalize(
    List<RootMikroManagerSalesRecord> records,
  ) {
    final seen = <String>{};
    final out = <VoucherSalesLedgerEntry>[];
    for (final r in records.where((e) => e.isValid)) {
      final key = const SalesRecordIdentity().strictKey(r);
      final duplicate = !seen.add(key);
      out.add(
        VoucherSalesLedgerEntry(
          username: r.username,
          profile: r.profile,
          amount: r.numericPrice,
          date: r.date,
          time: r.time,
          duplicate: duplicate,
        ),
      );
    }
    return out;
  }

  double uniqueRevenue(List<VoucherSalesLedgerEntry> entries) => entries
      .where((e) => !e.duplicate)
      .fold<double>(0, (sum, e) => sum + e.amount);

  int duplicateCount(List<VoucherSalesLedgerEntry> entries) =>
      entries.where((e) => e.duplicate).length;
}
