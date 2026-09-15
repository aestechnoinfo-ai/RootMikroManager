import 'rootmikromanager_sales_record.dart';
import 'sales_record_identity.dart';
import 'sales_date_utils.dart';

class SalesDataQualityResult {
  final int total;
  final int invalidRecords;
  final int invalidDates;
  final int negativePrices;
  final int emptyProfiles;
  final int duplicates;
  const SalesDataQualityResult({
    required this.total,
    required this.invalidRecords,
    required this.invalidDates,
    required this.negativePrices,
    required this.emptyProfiles,
    required this.duplicates,
  });
  bool get clean =>
      invalidRecords == 0 &&
      invalidDates == 0 &&
      negativePrices == 0 &&
      emptyProfiles == 0 &&
      duplicates == 0;
}

class SalesDataQualityService {
  const SalesDataQualityService();
  SalesDataQualityResult inspect(List<Map<String, String>> raw) {
    var invalid = 0, dates = 0, negative = 0, profiles = 0, duplicates = 0;
    final seen = <String>{};
    for (final source in raw) {
      final r = RootMikroManagerSalesRecord.fromRouterOs(source);
      if (!r.isValid) invalid++;
      if (SalesDateUtils.parse(r.date) == null) dates++;
      if (r.numericPrice < 0) negative++;
      if (r.profile.trim().isEmpty) profiles++;
      final key = const SalesRecordIdentity().strictKey(r);
      if (!seen.add(key)) duplicates++;
    }
    return SalesDataQualityResult(
      total: raw.length,
      invalidRecords: invalid,
      invalidDates: dates,
      negativePrices: negative,
      emptyProfiles: profiles,
      duplicates: duplicates,
    );
  }
}
