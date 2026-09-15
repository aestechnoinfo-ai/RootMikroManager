class BridgeVlanValidator {
  const BridgeVlanValidator._();

  static bool validVlanId(String value) {
    final id = int.tryParse(value.trim());
    return id != null && id >= 1 && id <= 4094;
  }

  static bool validVlanIds(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    for (final part in value.split(',')) {
      final token = part.trim();
      if (token.isEmpty) return false;
      if (token.contains('-')) {
        final pair = token.split('-');
        if (pair.length != 2) return false;
        final start = int.tryParse(pair[0].trim());
        final end = int.tryParse(pair[1].trim());
        if (start == null ||
            end == null ||
            start < 1 ||
            end > 4094 ||
            start > end) {
          return false;
        }
      } else if (!validVlanId(token)) {
        return false;
      }
    }
    return true;
  }

  static bool containsMultipleVlans(String raw) =>
      raw.contains(',') || raw.contains('-');

  static bool validMtu(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty || value == 'auto') return true;
    final mtu = int.tryParse(value);
    return mtu != null && mtu >= 576 && mtu <= 65535;
  }

  static bool validCost(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == 'auto') return true;
    final cost = int.tryParse(value);
    return cost != null && cost >= 0 && cost <= 200000000;
  }

  static bool validHorizon(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty || value == 'none') return true;
    final horizon = int.tryParse(value);
    return horizon != null && horizon >= 0 && horizon <= 4294967295;
  }

  static Set<String> splitMembers(String? raw) => (raw ?? '')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();

  static Set<int> expandVlanIds(String raw) {
    final out = <int>{};
    if (!validVlanIds(raw)) return out;
    for (final part in raw.split(',')) {
      final token = part.trim();
      if (token.contains('-')) {
        final pair = token.split('-');
        final start = int.parse(pair[0].trim());
        final end = int.parse(pair[1].trim());
        out.addAll(List<int>.generate(end - start + 1, (i) => start + i));
      } else {
        out.add(int.parse(token));
      }
    }
    return out;
  }
}
