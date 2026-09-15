class HotspotNameResolver {
  const HotspotNameResolver();

  String resolve(
    Iterable<Map<String, String>> interfaces, {
    Iterable<Map<String, String>> configurations = const [],
    String fallback = 'Hotspot',
  }) {
    final rows = [...interfaces];
    rows.sort((a, b) => _score(b).compareTo(_score(a)));
    for (final row in rows) {
      final ssid = _ssid(row);
      if (ssid.isNotEmpty) return ssid;
    }
    for (final row in configurations) {
      final ssid = _ssid(row);
      if (ssid.isNotEmpty) return ssid;
    }
    final safeFallback = fallback.trim();
    return safeFallback.isEmpty ? 'Hotspot' : safeFallback;
  }

  int _score(Map<String, String> row) {
    final disabled = _yes(row['disabled']);
    final running = _yes(row['running']);
    return (disabled ? 0 : 10) + (running ? 5 : 0);
  }

  String _ssid(Map<String, String> row) {
    for (final key in [
      'ssid',
      'configuration.ssid',
      'actual-configuration.ssid',
    ]) {
      final value = (row[key] ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _yes(String? value) => value == 'true' || value == 'yes';
}
