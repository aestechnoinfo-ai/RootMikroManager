import 'hotspot_profile_config.dart';
import 'mikhmon_time_parser.dart';

class HotspotProfileValidator {
  const HotspotProfileValidator();

  List<String> validate(
    HotspotProfileConfig config, {
    required List<Map<String, String>> existingProfiles,
  }) {
    final issues = <String>[];
    final name = config.name.trim();

    if (name.isEmpty) issues.add('Le nom du profil est obligatoire.');
    if (name.length > 64) issues.add('Le nom du profil est trop long.');
    if (config.sharedUsers < 1) {
      issues.add('Shared Users doit être supérieur ou égal à 1.');
    }

    final duplicate = existingProfiles.any((row) {
      final id = row['.id'];
      final rowName = (row['name'] ?? '').trim().toLowerCase();
      return rowName == name.toLowerCase() && id != config.id;
    });
    if (duplicate) issues.add('Un profil Hotspot porte déjà ce nom.');

    if (config.expirationMode != HotspotExpirationMode.none) {
      if (config.validity.trim().isEmpty) {
        issues.add('Une validité est obligatoire avec un mode d’expiration.');
      } else if (!_isTime(config.validity)) {
        issues.add(
          'Validité invalide. Exemples : 30min, 24h, 1jour, 4w, 3mois.',
        );
      }
    }

    if (config.gracePeriod.trim().isNotEmpty && !_isTime(config.gracePeriod)) {
      issues.add('Grace Period invalide.');
    }

    for (final item in [
      ('Price', config.price),
      ('Selling Price', config.sellingPrice),
    ]) {
      final value = double.tryParse(item.$2.replaceAll(',', '.'));
      if (value == null || value < 0) {
        issues.add('${item.$1} doit être un nombre positif ou nul.');
      }
    }

    if (config.rateLimit.trim().isNotEmpty &&
        !RegExp(r'^\S+(\/\S+)?$').hasMatch(config.rateLimit.trim())) {
      issues.add('Rate Limit invalide.');
    }

    return issues;
  }

  bool _isTime(String value) {
    try {
      MikhmonTimeParser.normalize(value);
      return true;
    } on FormatException {
      return false;
    }
  }
}
