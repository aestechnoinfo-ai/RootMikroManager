class NetworkInputValidator {
  const NetworkInputValidator._();

  static String? ipv4(String? value, {String label = 'Adresse IPv4'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$label obligatoire.';
    return _isIpv4(text) ? null : '$label invalide.';
  }

  static String? ipv4OrEmpty(String? value, {String label = 'Adresse IPv4'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    return _isIpv4(text) ? null : '$label invalide.';
  }

  static String? ipOrCidr(
    String? value, {
    required String label,
    bool allowEmpty = true,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return allowEmpty ? null : '$label obligatoire.';
    if (text.contains(':')) {
      final parts = text.split('/');
      if (parts.length > 2) return '$label invalide.';
      final addressError = ipv6(parts.first, label: label);
      if (addressError != null) return addressError;
      if (parts.length == 2) {
        final prefix = int.tryParse(parts.last);
        if (prefix == null || prefix < 0 || prefix > 128) {
          return 'Préfixe IPv6 invalide (0 à 128).';
        }
      }
      return null;
    }
    if (text.contains('/')) return ipv4Cidr(text, label: label);
    return ipv4(text, label: label);
  }

  static String? ipv6Cidr(String? value, {String label = 'Destination IPv6'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$label obligatoire.';
    final parts = text.split('/');
    if (parts.length != 2) return '$label invalide.';
    final addressError = ipv6(parts.first, label: label);
    if (addressError != null) return addressError;
    final prefix = int.tryParse(parts.last);
    if (prefix == null || prefix < 0 || prefix > 128) {
      return 'Préfixe IPv6 invalide (0 à 128).';
    }
    return null;
  }

  static String? ipv6Gateway(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Gateway IPv6 obligatoire.';
    final candidate = text.contains('@') ? text.split('@').first : text;
    final address = candidate.contains('%')
        ? candidate.split('%').first
        : candidate;
    if (address.contains(':')) return ipv6(address, label: 'Gateway IPv6');
    return _validName(address) ? null : 'Gateway IPv6 ou interface invalide.';
  }

  static String? ipv6(String? value, {String label = 'Adresse IPv6'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$label obligatoire.';
    if (!text.contains(':') ||
        !RegExp(r'^[0-9A-Fa-f:]+$').hasMatch(text) ||
        text.split(':').length > 9) {
      return '$label invalide.';
    }
    return null;
  }

  static String? ipv4Cidr(String? value, {String label = 'Adresse/prefix'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$label obligatoire.';
    final parts = text.split('/');
    if (parts.length != 2 || !_isIpv4(parts.first)) {
      return '$label invalide. Exemple : 192.168.88.1/24';
    }
    final prefix = int.tryParse(parts.last);
    if (prefix == null || prefix < 0 || prefix > 32) {
      return 'Préfixe IPv4 invalide (0 à 32).';
    }
    return null;
  }

  static String? routeDestination(String? value) =>
      ipv4Cidr(value, label: 'Destination');

  static String? gateway(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Gateway obligatoire.';
    final gateways = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    if (gateways.isEmpty) return 'Gateway obligatoire.';
    for (final item in gateways) {
      var candidate = item;
      if (candidate.contains('@')) candidate = candidate.split('@').first;
      if (candidate.contains('%')) candidate = candidate.split('%').first;
      if (_isIpv4(candidate) || _validName(candidate)) continue;
      return 'Gateway invalide : IPv4, interface ou syntaxe RouterOS attendue.';
    }
    return null;
  }

  static String? mac(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Adresse MAC obligatoire.';
    final rx = RegExp(r'^[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}$');
    return rx.hasMatch(text) ? null : 'Adresse MAC invalide.';
  }

  static String? dnsForwardTarget(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Forward To obligatoire.';
    final asServers = dnsServerList(text, label: 'Forward To');
    if (asServers == null) return null;
    return _validName(text) ? null : asServers;
  }

  static String? dnsServerList(String? value, {String label = 'Serveurs DNS'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    for (final raw in text.split(',').map((e) => e.trim())) {
      if (raw.isEmpty) return '$label invalide.';
      final address = raw.contains('@') ? raw.split('@').first : raw;
      if (!_isIpv4(address) &&
          !(address.contains(':') &&
              RegExp(r'^[0-9A-Fa-f:]+$').hasMatch(address))) {
        return '$label invalide : $raw';
      }
    }
    return null;
  }

  static String? ipv4List(
    String? value, {
    String label = 'Adresses IPv4',
    bool allowEmpty = true,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return allowEmpty ? null : '$label obligatoire.';
    for (final item in text.split(',').map((e) => e.trim())) {
      if (item.isEmpty || !_isIpv4(item)) return '$label invalide : $item';
    }
    return null;
  }

  static String? routerOsDuration(
    String? value, {
    required String label,
    bool allowEmpty = false,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return allowEmpty ? null : '$label obligatoire.';
    if (text == '0' || text == '0s') return null;
    final compact = RegExp(r'^(?:\d+w)?(?:\d+d)?(?:\d+h)?(?:\d+m)?(?:\d+s)?$');
    final clock = RegExp(r'^(?:\d+d\s+)?\d{1,2}:\d{2}:\d{2}$');
    if ((!compact.hasMatch(text) && !clock.hasMatch(text)) ||
        !RegExp(r'\d').hasMatch(text)) {
      return '$label invalide. Exemple : 30m, 1h, 1d ou 00:30:00.';
    }
    return null;
  }

  static String? dnsName(
    String? value, {
    String label = 'Nom DNS',
    bool allowEmpty = false,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return allowEmpty ? null : '$label obligatoire.';
    if (text.length > 253) return '$label trop long.';
    final candidate = text.endsWith('.')
        ? text.substring(0, text.length - 1)
        : text;
    final labels = candidate.split('.');
    final labelRx = RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9_-]{0,61}[A-Za-z0-9])?$');
    if (labels.any((part) => part.isEmpty || !labelRx.hasMatch(part))) {
      return '$label invalide.';
    }
    return null;
  }

  static String? httpUrl(String? value, {String label = 'URL'}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$label obligatoire.';
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return '$label HTTP/HTTPS invalide.';
    }
    return null;
  }

  static String? positiveInteger(
    String? value, {
    required String label,
    int min = 1,
    int? max,
  }) {
    final text = (value ?? '').trim();
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < min || (max != null && parsed > max)) {
      return max == null
          ? '$label doit être supérieur ou égal à $min.'
          : '$label doit être compris entre $min et $max.';
    }
    return null;
  }

  static String? interfaceName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Nom obligatoire.';
    if (text.length > 63) return 'Nom trop long (63 caractères maximum).';
    if (!_validName(text)) return 'Nom d’interface invalide.';
    return null;
  }

  static String? integerRange(
    String? value, {
    required String label,
    required int min,
    required int max,
    bool allowEmpty = false,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty && allowEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < min || parsed > max) {
      return '$label doit être compris entre $min et $max.';
    }
    return null;
  }

  static bool _isIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      if (part.isEmpty || (part.length > 1 && part.startsWith('0'))) {
        // RouterOS accepts normal decimal notation; rejecting ambiguous octal-like
        // input avoids accidental addresses such as 010.000.000.001.
        if (part != '0') return false;
      }
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  static bool _validName(String value) =>
      RegExp(r'^[^\s/]+(?: [^/]+)*$').hasMatch(value);
}
