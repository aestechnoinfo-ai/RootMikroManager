class VoucherBatchValidator {
  const VoucherBatchValidator();

  String? quantity(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null) return 'Quantité invalide.';
    if (value < 1 || value > 560)
      return 'La quantité doit être comprise entre 1 et 560.';
    return null;
  }

  String? prefixSuffix(String value, String label) {
    final text = value.trim();
    if (text.length > 6) return '$label limité à 6 caractères.';
    if (text.contains(RegExp(r'\s')))
      return '$label ne doit pas contenir d’espace.';
    return null;
  }

  String? time(String value) {
    final text = value.trim();
    if (text.isEmpty || text == '0') return null;
    if (!RegExp(r'^(\d+[wdhms])+$', caseSensitive: false).hasMatch(text)) {
      return 'Durée invalide. Exemples : 30m, 1h, 1h30m, 2d.';
    }
    return null;
  }

  String? data(String value) {
    if (value.trim().isEmpty) return null;
    final n = int.tryParse(value.trim());
    if (n == null || n < 0) return 'Data Limit doit être un entier positif.';
    return null;
  }

  List<String> validate({
    required String quantityRaw,
    required String prefix,
    required String suffix,
    required String timeLimit,
    required String dataLimit,
    required String? profile,
  }) {
    final out = <String>[];
    for (final e in [
      quantity(quantityRaw),
      prefixSuffix(prefix, 'Préfixe'),
      prefixSuffix(suffix, 'Suffixe'),
      time(timeLimit),
      data(dataLimit),
      if (profile == null || profile.trim().isEmpty)
        'Sélectionnez un profil Hotspot.'
      else
        null,
    ]) {
      if (e != null) out.add(e);
    }
    return out;
  }
}
