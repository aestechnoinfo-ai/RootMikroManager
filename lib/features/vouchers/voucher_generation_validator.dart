class VoucherGenerationValidator {
  static List<String> validate({
    required int quantity,
    required int length,
    required String characterMode,
    required String prefix,
    required String suffix,
    required String profile,
    required String server,
    required String timeLimit,
    required String dataLimit,
  }) {
    final out = <String>[];
    if (quantity < 1 || quantity > 560)
      out.add('Quantité autorisée : 1 à 560 tickets par lot.');
    if (length < 3 || length > 8)
      out.add('Longueur aléatoire autorisée : 3 à 8 caractères.');
    if (prefix.length > 6) out.add('Préfixe limité à 6 caractères.');
    if (suffix.length > 6) out.add('Suffixe limité à 6 caractères.');
    if (profile.trim().isEmpty) out.add('Profil Hotspot requis.');
    if (server.trim().isEmpty) out.add('Serveur Hotspot requis.');
    if (timeLimit.trim().isNotEmpty &&
        !RegExp(r'^\d+[smhdw](\d+[smhdw])*$').hasMatch(timeLimit.trim()))
      out.add('Limite de temps invalide, ex. 1h, 30m ou 1h30m.');
    if (dataLimit.trim().isNotEmpty &&
        (int.tryParse(dataLimit.trim()) ?? -1) < 0)
      out.add('Limite de données invalide.');
    final alphabetSize = switch (characterMode) {
      'num' => 8,
      'lower' || 'upper' => 23,
      'upplow' => 46,
      'mix' || 'mix1' => 31,
      'mix2' => 54,
      _ => 0,
    };
    if (alphabetSize > 0) {
      final combinations = _pow(alphabetSize, length);
      if (quantity > combinations) {
        out.add(
          'Ce jeu de caractères ne fournit que $combinations codes distincts '
          'avec une longueur de $length.',
        );
      }
    }
    return out;
  }

  static int _pow(int base, int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) result *= base;
    return result;
  }
}
