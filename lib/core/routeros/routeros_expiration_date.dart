/// Compatibilité avec les dates d'expiration historiques sous RouterOS 6
/// (`aug/31/2026 12:30:00`) et RouterOS 7
/// (`2026-08-31 12:30:00`).
class RouterOsExpirationDate {
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

  static final _iso = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?$',
  );
  static final _legacy = RegExp(
    r'^([a-zA-Z]{3})/(\d{1,2})/(\d{4})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?$',
  );

  const RouterOsExpirationDate._();

  static DateTime? tryParse(String? value, {bool utc = false}) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;

    final iso = _iso.firstMatch(text);
    if (iso != null) {
      return _date(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
        _number(iso.group(4)),
        _number(iso.group(5)),
        _number(iso.group(6)),
        utc,
      );
    }

    final legacy = _legacy.firstMatch(text);
    if (legacy != null) {
      final month = _months[legacy.group(1)!.toLowerCase()];
      if (month == null) return null;
      return _date(
        int.parse(legacy.group(3)!),
        month,
        int.parse(legacy.group(2)!),
        _number(legacy.group(4)),
        _number(legacy.group(5)),
        _number(legacy.group(6)),
        utc,
      );
    }
    return null;
  }

  static bool isExpired(String? value, DateTime now) {
    final expiration = tryParse(value, utc: now.isUtc);
    return expiration != null && !expiration.isAfter(now);
  }

  static int _number(String? value) => value == null ? 0 : int.parse(value);

  static DateTime? _date(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
    bool utc,
  ) {
    final result = utc
        ? DateTime.utc(year, month, day, hour, minute, second)
        : DateTime(year, month, day, hour, minute, second);
    if (result.year != year || result.month != month || result.day != day) {
      return null;
    }
    return result;
  }
}
