import 'rootmikromanager_sales_record.dart';
import 'sales_record_identity.dart';

class SalesUniqueRevenueResult {
  final int rawCount;
  final int validCount;
  final int uniqueCount;
  final int duplicateCount;
  final double uniqueRevenue;

  const SalesUniqueRevenueResult({
    required this.rawCount,
    required this.validCount,
    required this.uniqueCount,
    required this.duplicateCount,
    required this.uniqueRevenue,
  });
}

class SalesUniqueRevenueService {
  const SalesUniqueRevenueService();

  SalesUniqueRevenueResult calculate(List<Map<String, String>> raw) {
    final valid = raw
        .map(RootMikroManagerSalesRecord.fromRouterOs)
        .where((e) => e.isValid)
        .toList();
    final seen = <String>{};
    var revenue = 0.0;
    var duplicates = 0;

    for (final row in valid) {
      final key = const SalesRecordIdentity().strictKey(row);
      if (!seen.add(key)) {
        duplicates++;
        continue;
      }
      revenue += row.numericPrice;
    }

    return SalesUniqueRevenueResult(
      rawCount: raw.length,
      validCount: valid.length,
      uniqueCount: seen.length,
      duplicateCount: duplicates,
      uniqueRevenue: revenue,
    );
  }
}
