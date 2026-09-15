class WifiWirelessValidator {
  const WifiWirelessValidator._();

  static String? name(String? value, {String label = 'Nom'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$label obligatoire.';
    if (text.length > 63) return '$label trop long.';
    return text.contains('\n') ? '$label invalide.' : null;
  }

  static String? macOrEmpty(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    return RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$').hasMatch(text)
        ? null
        : 'Adresse MAC invalide.';
  }

  static String? vlanOrEmpty(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final n = int.tryParse(text);
    return n != null && n >= 1 && n <= 4094
        ? null
        : 'VLAN ID invalide (1–4094).';
  }

  static String? signalRangeOrEmpty(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final m = RegExp(r'^(-?\d+)\.\.(-?\d+)$').firstMatch(text);
    if (m == null) return 'Signal Range attendu, ex. -120..-70.';
    final low = int.parse(m.group(1)!);
    final high = int.parse(m.group(2)!);
    if (low < -200 || high > 200 || low > high) {
      return 'Signal Range incohérent.';
    }
    return null;
  }

  static String? passphrase(String? value, {required String authentication}) {
    final text = (value ?? '').trim();
    final psk = authentication.contains('-psk');
    if (!psk) return null;
    if (text.isEmpty) return null; // écriture optionnelle lors d'une édition
    if (text.length >= 8 && text.length <= 63) return null;
    if (RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(text)) return null;
    return 'Passphrase WPA-PSK : 8–63 caractères ou 64 chiffres hexadécimaux.';
  }

  static String? frequencyOrEmpty(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text == 'auto') return null;
    for (final part in text.split(',')) {
      final clean = part.trim();
      if (RegExp(r'^\d+(?:-\d+)?$').hasMatch(clean)) continue;
      return 'Fréquence invalide.';
    }
    return null;
  }

  static String? provisioningMac(String? value) => macOrEmpty(value);
}
