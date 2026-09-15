class VpnInputValidator {
  const VpnInputValidator._();

  static String? name(String? value, {String label = 'Nom'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$label obligatoire.';
    if (text.length > 63) return '$label trop long.';
    return text.contains('\n') ? '$label invalide.' : null;
  }

  static String? port(
    String? value, {
    String label = 'Port',
    bool allowEmpty = false,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return allowEmpty ? null : '$label obligatoire.';
    final n = int.tryParse(text);
    return n != null && n >= 1 && n <= 65535
        ? null
        : '$label invalide (1–65535).';
  }

  static String? mtu(String? value) {
    final n = int.tryParse((value ?? '').trim());
    return n != null && n >= 576 && n <= 65536
        ? null
        : 'MTU invalide (576–65536).';
  }

  static String? wireGuardKey(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Clé publique obligatoire.';
    return RegExp(r'^[A-Za-z0-9+/]{43}=$').hasMatch(text)
        ? null
        : 'Clé WireGuard Base64 invalide.';
  }

  static String? allowedAddresses(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Allowed Address obligatoire.';
    for (final raw in text.split(',')) {
      final item = raw.trim();
      final p = item.split('/');
      if (p.length != 2) return 'Allowed Address invalide : $item';
      final prefix = int.tryParse(p.last);
      if (item.contains(':')) {
        if (prefix == null ||
            prefix < 0 ||
            prefix > 128 ||
            !RegExp(r'^[0-9A-Fa-f:]+$').hasMatch(p.first)) {
          return 'Allowed Address IPv6 invalide : $item';
        }
      } else {
        final octets = p.first.split('.');
        if (octets.length != 4 || prefix == null || prefix < 0 || prefix > 32)
          return 'Allowed Address IPv4 invalide : $item';
        for (final o in octets) {
          final n = int.tryParse(o);
          if (n == null || n < 0 || n > 255)
            return 'Allowed Address IPv4 invalide : $item';
        }
      }
    }
    return null;
  }

  static String? keepalive(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final n = int.tryParse(text);
    return n != null && n >= 0 && n <= 65535
        ? null
        : 'Persistent Keepalive invalide.';
  }

  static String? zeroTierNetworkId(String? value) {
    final text = (value ?? '').trim();
    return RegExp(r'^[0-9A-Fa-f]{16}$').hasMatch(text)
        ? null
        : 'Network ID ZeroTier attendu : 16 caractères hexadécimaux.';
  }
}
