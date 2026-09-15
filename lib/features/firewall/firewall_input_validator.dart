class FirewallInputValidator {
  const FirewallInputValidator._();

  static String? chain(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Chain obligatoire.';
    return RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(text)
        ? null
        : 'Chain invalide.';
  }

  static String? ipOrCidrOrEmpty(String? value, {String label = 'Adresse'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final candidate = text.startsWith('!') ? text.substring(1) : text;
    final parts = candidate.split('/');
    if (parts.length > 2) return '$label invalide.';
    final octets = parts.first.split('.');
    if (octets.length != 4) return '$label IPv4/CIDR invalide.';
    for (final part in octets) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return '$label IPv4/CIDR invalide.';
    }
    if (parts.length == 2) {
      final prefix = int.tryParse(parts.last);
      if (prefix == null || prefix < 0 || prefix > 32)
        return 'Préfixe IPv4 invalide.';
    }
    return null;
  }

  static String? ipv4RangeOrCidrOrEmpty(
    String? value, {
    String label = 'Adresse',
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final candidate = text.startsWith('!') ? text.substring(1) : text;
    if (candidate.contains('-')) {
      final ends = candidate.split('-');
      if (ends.length != 2) return '$label invalide.';
      final first = ipOrCidrOrEmpty(ends.first, label: label);
      final last = ipOrCidrOrEmpty(ends.last, label: label);
      return first ?? last;
    }
    return ipOrCidrOrEmpty(candidate, label: label);
  }

  static String? ports(String? value, {String label = 'Ports'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    for (final raw in text.split(',')) {
      final item = raw.trim();
      final clean = item.startsWith('!') ? item.substring(1) : item;
      final bounds = clean.split('-');
      if (bounds.length > 2) return '$label invalide.';
      final first = int.tryParse(bounds.first);
      final last = bounds.length == 2 ? int.tryParse(bounds.last) : first;
      if (first == null ||
          last == null ||
          first < 0 ||
          last > 65535 ||
          first > last) {
        return '$label invalide (0–65535).';
      }
    }
    return null;
  }

  static String? connectionStates(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    const allowed = {'established', 'invalid', 'new', 'related', 'untracked'};
    for (final raw in text.split(',')) {
      final state = raw.trim().replaceFirst('!', '');
      if (!allowed.contains(state)) return 'Connection State invalide : $raw';
    }
    return null;
  }

  static String? addressListName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Nom de liste obligatoire.';
    if (text.length > 63) return 'Nom de liste trop long.';
    return text.contains('\n') ? 'Nom de liste invalide.' : null;
  }

  static String? timeout(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (text == 'none-dynamic') return null;
    final compact = RegExp(r'^(?:\d+w)?(?:\d+d)?(?:\d+h)?(?:\d+m)?(?:\d+s)?$');
    return compact.hasMatch(text) && RegExp(r'\d').hasMatch(text)
        ? null
        : 'Timeout invalide. Exemple : 1h, 1d ou 1w2d.';
  }

  static String? mark(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'New Mark obligatoire pour cette action.';
    return text.length <= 63 ? null : 'New Mark trop long.';
  }
}
