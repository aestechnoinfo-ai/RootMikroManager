class PppSecretValidator {
  const PppSecretValidator();

  List<String> validate({
    required String name,
    required String service,
    required String profile,
    required String localAddress,
    required String remoteAddress,
    required List<Map<String, String>> profiles,
    required List<Map<String, String>> pools,
  }) {
    final issues = <String>[];
    if (name.trim().isEmpty) issues.add('Nom du secret obligatoire.');

    const services = {'any', 'async', 'l2tp', 'ovpn', 'pppoe', 'pptp', 'sstp'};
    if (!services.contains(service)) {
      issues.add('Service PPP non reconnu.');
    }

    final profileNames = profiles.map((e) => e['name'] ?? '').toSet();
    if (profile.trim().isEmpty || !profileNames.contains(profile)) {
      issues.add('Le profil PPP sélectionné n’existe pas.');
    }

    final poolNames = pools.map((e) => e['name'] ?? '').toSet();
    for (final item in [
      ('Adresse locale', localAddress),
      ('Adresse distante', remoteAddress),
    ]) {
      final value = item.$2.trim();
      if (value.isEmpty) continue;
      if (!_looksLikeIp(value) && !poolNames.contains(value)) {
        issues.add('${item.$1} "$value" n’est ni une IP ni un pool connu.');
      }
    }
    return issues;
  }

  bool _looksLikeIp(String value) {
    final base = value.split('/').first;
    final parts = base.split('.');
    if (parts.length != 4) return false;
    return parts.every((p) {
      final n = int.tryParse(p);
      return n != null && n >= 0 && n <= 255;
    });
  }
}
