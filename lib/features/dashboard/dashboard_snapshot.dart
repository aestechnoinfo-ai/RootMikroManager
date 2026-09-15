import '../reports/rootmikromanager_sales_record.dart';

class DashboardSnapshot {
  final Map<String, String> identity;
  final Map<String, String> resource;
  final Map<String, String> clock;
  final Map<String, String> routerboard;
  final List<Map<String, String>> hotspotActive;
  final List<Map<String, String>> pppActive;
  final Map<String, int> remainingTicketsByProfile;
  final int remainingTicketsTotal;
  final List<Map<String, String>> logs;
  final List<Map<String, String>> interfaces;
  final double salesToday;
  final double salesWeek;
  final double salesMonth;
  final double salesTotal;

  const DashboardSnapshot({
    required this.identity,
    required this.resource,
    required this.clock,
    required this.routerboard,
    required this.hotspotActive,
    required this.pppActive,
    required this.remainingTicketsByProfile,
    required this.remainingTicketsTotal,
    required this.logs,
    required this.interfaces,
    required this.salesToday,
    required this.salesWeek,
    required this.salesMonth,
    required this.salesTotal,
  });

  static DashboardSnapshot fromRaw({
    required Map<String, String> identity,
    required Map<String, String> resource,
    required Map<String, String> clock,
    required Map<String, String> routerboard,
    required List<Map<String, String>> hotspotActive,
    required List<Map<String, String>> pppActive,
    required List<Map<String, String>> hotspotUsers,
    required List<Map<String, String>> salesRows,
    required List<Map<String, String>> logs,
    required List<Map<String, String>> interfaces,
    required DateTime now,
  }) {
    final remaining = <String, int>{};

    bool unusedTicket(Map<String, String> row) {
      final disabled = (row['disabled'] ?? '').toLowerCase();
      final uptime = (row['uptime'] ?? '').trim().toLowerCase();
      final limit = (row['limit-uptime'] ?? '').trim().toLowerCase();
      final comment = (row['comment'] ?? '').trim().toLowerCase();

      // Les vouchers générés utilisent la signature de lot historique
      // up/vc-NNN-MM.DD.YY-... ; les comptes Hotspot ordinaires ne sont
      // donc pas comptés comme tickets restants.
      final isVoucher = RegExp(
        r'^(up|vc)-\d{3}-\d{2}\.\d{2}\.\d{2}(?:-|$)',
      ).hasMatch(comment);

      if (!isVoucher) return false;
      if (disabled == 'yes' || disabled == 'true') return false;
      if (limit == '1s') return false;

      return uptime.isEmpty ||
          uptime == '0' ||
          uptime == '0s' ||
          uptime == '00:00:00';
    }

    for (final row in hotspotUsers) {
      final profile = (row['profile'] ?? '').trim();
      if (profile.isEmpty) continue;
      final serverCount = int.tryParse(row['dashboard-count'] ?? '');
      if (serverCount != null) {
        if (serverCount > 0) remaining[profile] = serverCount;
        continue;
      }
      // Compatibility with existing tests/callers that still provide rows.
      if (unusedTicket(row)) {
        remaining.update(profile, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final records = salesRows
        .map(RootMikroManagerSalesRecord.fromRouterOs)
        .where((e) => e.username.isNotEmpty)
        .toList();

    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final monthStart = DateTime(now.year, now.month, 1);

    double dayRevenue = 0;
    double weekRevenue = 0;
    double monthRevenue = 0;
    double totalRevenue = 0;

    for (final record in records) {
      totalRevenue += record.numericPrice;
      final date = parseReportDate(record.date, fallbackYear: now.year);
      if (date == null) continue;

      final normalized = DateTime(date.year, date.month, date.day);
      if (normalized == today) dayRevenue += record.numericPrice;
      if (!normalized.isBefore(weekStart) && !normalized.isAfter(today)) {
        weekRevenue += record.numericPrice;
      }
      if (!normalized.isBefore(monthStart) &&
          normalized.year == now.year &&
          normalized.month == now.month) {
        monthRevenue += record.numericPrice;
      }
    }

    return DashboardSnapshot(
      identity: identity,
      resource: resource,
      clock: clock,
      routerboard: routerboard,
      hotspotActive: hotspotActive,
      pppActive: pppActive,
      remainingTicketsByProfile: remaining,
      remainingTicketsTotal: remaining.values.fold(
        0,
        (sum, value) => sum + value,
      ),
      logs: logs,
      interfaces: interfaces,
      salesToday: dayRevenue,
      salesWeek: weekRevenue,
      salesMonth: monthRevenue,
      salesTotal: totalRevenue,
    );
  }

  static DateTime? parseReportDate(String value, {required int fallbackYear}) {
    final raw = value.trim().toLowerCase();
    if (raw.isEmpty) return null;

    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

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

    final parts = raw.split(RegExp(r'[/\-.]'));
    if (parts.length != 3) return null;

    final firstMonth = months[parts[0]];
    if (firstMonth != null) {
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]) ?? fallbackYear;
      if (day != null) return DateTime(year, firstMonth, day);
    }

    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);
    if (a == null || b == null || c == null) return null;

    if (a > 31) return DateTime(a, b, c);
    if (c > 31) {
      // Existing RootMikroManager reports may use MM/DD/YYYY.
      return DateTime(c, a, b);
    }
    return null;
  }
}
