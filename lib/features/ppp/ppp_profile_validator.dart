class PppProfileValidator {
  const PppProfileValidator();

  List<String> validate({
    required String name,
    required String localAddress,
    required String remoteAddress,
    required String rateLimit,
    required String sessionTimeout,
    required String idleTimeout,
    required String? currentId,
    required List<Map<String, String>> profiles,
    required List<Map<String, String>> pools,
  }) {
    final issues = <String>[];
    final safeName = name.trim();

    if (safeName.isEmpty) issues.add('Nom du profil obligatoire.');

    final duplicate = profiles.any(
      (row) =>
          row['.id'] != currentId &&
          (row['name'] ?? '').trim().toLowerCase() == safeName.toLowerCase(),
    );
    if (duplicate) issues.add('Un profil PPP porte déjà ce nom.');

    final poolNames = pools.map((e) => e['name'] ?? '').toSet();
    for (final item in [
      ('Adresse locale', localAddress),
      ('Adresse distante', remoteAddress),
    ]) {
      final value = item.$2.trim();
      if (value.isEmpty) continue;
      if (!_looksLikeIp(value) && !poolNames.contains(value)) {
        issues.add('${item.$1} "$value" ne correspond à aucun pool connu.');
      }
    }

    if (rateLimit.trim().isNotEmpty &&
        !RegExp(r'^\S+(\/\S+)?$').hasMatch(rateLimit.trim())) {
      issues.add('Rate limit invalide.');
    }

    for (final item in [
      ('Session timeout', sessionTimeout),
      ('Idle timeout', idleTimeout),
    ]) {
      final value = item.$2.trim();
      if (value.isNotEmpty &&
          !RegExp(r'^(\d+[wdhms])+$', caseSensitive: false).hasMatch(value)) {
        issues.add('${item.$1} invalide.');
      }
    }

    return issues;
  }

  bool _looksLikeIp(String value) =>
      RegExp(r'^\d{1,3}(\.\d{1,3}){3}(/\d{1,2})?$').hasMatch(value);
}
