import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';
import 'sales_date_utils.dart';

class LiveReportSnapshot {
  final int todayVouchers;
  final double todayIncome;
  final int weekVouchers;
  final double weekIncome;
  final int monthVouchers;
  final double monthIncome;
  final int totalVouchers;
  final double totalIncome;
  final String currency;
  final Map<String, double> monthByProfile;

  const LiveReportSnapshot({
    required this.todayVouchers,
    required this.todayIncome,
    required this.weekVouchers,
    required this.weekIncome,
    required this.monthVouchers,
    required this.monthIncome,
    required this.totalVouchers,
    required this.totalIncome,
    required this.currency,
    required this.monthByProfile,
  });
}

class LiveReportService {
  final RouterOsService service;
  const LiveReportService(this.service);

  Future<LiveReportSnapshot> load() async {
    final values = await Future.wait([
      service.rootmikromanagerSalesScripts(),
      service.systemClock(),
      AppCurrencySettings.load(),
    ]);
    final scripts = values[0] as List<Map<String, String>>;
    final clock = values[1] as Map<String, String>;
    final currency = values[2] as String;
    final records = scripts
        .map(RootMikroManagerSalesRecord.fromRouterOs)
        .where((r) => r.isValid)
        .toList();

    final now = _routerDate(clock) ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);

    bool inRange(DateTime? d, DateTime start, DateTime end) =>
        d != null && !d.isBefore(start) && d.isBefore(end);

    double total(Iterable<RootMikroManagerSalesRecord> rows) =>
        rows.fold(0, (sum, row) => sum + row.numericPrice);

    final dayRows = records
        .where(
          (r) => inRange(
            SalesDateUtils.parse(r.date),
            today,
            today.add(const Duration(days: 1)),
          ),
        )
        .toList();
    final weekRows = records
        .where(
          (r) => inRange(
            SalesDateUtils.parse(r.date),
            weekStart,
            today.add(const Duration(days: 1)),
          ),
        )
        .toList();
    final monthRows = records
        .where(
          (r) => inRange(SalesDateUtils.parse(r.date), monthStart, nextMonth),
        )
        .toList();

    final byProfile = <String, double>{};
    for (final row in monthRows) {
      final profile = row.profile.trim().isEmpty ? 'Sans profil' : row.profile;
      byProfile[profile] = (byProfile[profile] ?? 0) + row.numericPrice;
    }

    return LiveReportSnapshot(
      todayVouchers: dayRows.length,
      todayIncome: total(dayRows),
      weekVouchers: weekRows.length,
      weekIncome: total(weekRows),
      monthVouchers: monthRows.length,
      monthIncome: total(monthRows),
      totalVouchers: records.length,
      totalIncome: total(records),
      currency: currency,
      monthByProfile: byProfile,
    );
  }

  DateTime? _routerDate(Map<String, String> clock) {
    final raw = (clock['date'] ?? '').trim();
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    final p = raw.split('/');
    if (p.length == 3) {
      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final m = months[p[0].toLowerCase().substring(0, 3)];
      final d = int.tryParse(p[1]);
      final y = int.tryParse(p[2]);
      if (m != null && d != null && y != null) return DateTime(y, m, d);
    }
    return null;
  }
}
