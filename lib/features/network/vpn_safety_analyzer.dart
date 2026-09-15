class VpnSafetyIssue {
  final String code;
  final String message;
  final bool critical;
  const VpnSafetyIssue({
    required this.code,
    required this.message,
    this.critical = false,
  });
}

class VpnSafetyAnalyzer {
  const VpnSafetyAnalyzer._();

  static List<VpnSafetyIssue> wireGuardPeer({
    required String allowed,
    required String endpoint,
    required int keepalive,
  }) {
    final issues = <VpnSafetyIssue>[];
    if (allowed
        .split(',')
        .map((e) => e.trim())
        .any((e) => e == '0.0.0.0/0' || e == '::/0')) {
      issues.add(
        const VpnSafetyIssue(
          code: 'default-route',
          message:
              'Allowed Address contient une route par défaut. Le peer peut devenir un chemin de sortie global si le routage associé est configuré.',
          critical: true,
        ),
      );
    }
    if (endpoint.trim().isEmpty && keepalive > 0) {
      issues.add(
        const VpnSafetyIssue(
          code: 'keepalive-no-endpoint',
          message:
              'Persistent Keepalive est configuré sans endpoint statique. Vérifiez que ce comportement est attendu.',
        ),
      );
    }
    return issues;
  }

  static List<VpnSafetyIssue> zeroTier({
    required bool allowDefault,
    required bool allowGlobal,
  }) {
    final issues = <VpnSafetyIssue>[];
    if (allowDefault) {
      issues.add(
        const VpnSafetyIssue(
          code: 'zt-default',
          message:
              'allow-default permet au contrôleur ZeroTier d’installer une route par défaut et peut modifier le chemin de management.',
          critical: true,
        ),
      );
    }
    if (allowGlobal) {
      issues.add(
        const VpnSafetyIssue(
          code: 'zt-global',
          message:
              'allow-global autorise des routes gérées dans l’espace IP public. Vérifiez les routes distribuées par le contrôleur.',
        ),
      );
    }
    return issues;
  }
}
