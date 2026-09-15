class SalesDateUtils {
  static const _months = <String, int>{
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

  static DateTime? parse(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(value);
    if (iso != null) return _safe(iso.group(1), iso.group(2), iso.group(3));
    final slash = value.split('/');
    if (slash.length == 3) {
      final year = int.tryParse(slash[2]);
      final day = int.tryParse(slash[1]);
      final first = int.tryParse(slash[0]);
      if (year != null && day != null) {
        final month =
            first ??
            _months[slash[0].substring(
              0,
              slash[0].length < 3 ? slash[0].length : 3,
            )];
        if (month != null) return _date(year, month, day);
      }
    }
    return null;
  }

  static DateTime? _safe(String? y, String? m, String? d) {
    final yy = int.tryParse(y ?? ''),
        mm = int.tryParse(m ?? ''),
        dd = int.tryParse(d ?? '');
    if (yy == null || mm == null || dd == null) return null;
    return _date(yy, mm, dd);
  }

  static DateTime? _date(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final value = DateTime(y, m, d);
    return value.year == y && value.month == m && value.day == d ? value : null;
  }

  static bool sameDay(String raw, DateTime target) {
    final d = parse(raw);
    return d != null &&
        d.year == target.year &&
        d.month == target.month &&
        d.day == target.day;
  }

  static bool sameMonth(String raw, DateTime target) {
    final d = parse(raw);
    return d != null && d.year == target.year && d.month == target.month;
  }

  static bool inRange(String raw, DateTime start, DateTime end) {
    final d = parse(raw);
    if (d == null) return false;
    final x = DateTime(d.year, d.month, d.day),
        a = DateTime(start.year, start.month, start.day),
        b = DateTime(end.year, end.month, end.day);
    return !x.isBefore(a) && !x.isAfter(b);
  }
}
