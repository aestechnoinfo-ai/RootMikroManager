class WifiSafetyIssue {
  final String code;
  final String message;
  final bool critical;
  const WifiSafetyIssue({
    required this.code,
    required this.message,
    this.critical = false,
  });
}

class WifiWirelessSafetyAnalyzer {
  const WifiWirelessSafetyAnalyzer._();

  static List<WifiSafetyIssue> security({
    required String authentication,
    required String passphrase,
  }) {
    final issues = <WifiSafetyIssue>[];
    if (authentication.isEmpty) {
      issues.add(
        const WifiSafetyIssue(
          code: 'auth-empty',
          message:
              'Aucun type d’authentification n’est sélectionné. Vérifiez qu’un réseau ouvert est réellement souhaité.',
          critical: true,
        ),
      );
    }
    if (authentication.contains('wpa2-psk') &&
        !authentication.contains('wpa3-psk')) {
      issues.add(
        const WifiSafetyIssue(
          code: 'wpa2-only',
          message:
              'WPA2-PSK seul reste compatible avec les anciens clients, mais WPA3 peut être préférable lorsque le matériel le permet.',
        ),
      );
    }
    return issues;
  }

  static List<WifiSafetyIssue> accessRule({
    required String action,
    required String mac,
    required String interfaceName,
    required String ssidRegexp,
    required String signalRange,
  }) {
    final issues = <WifiSafetyIssue>[];
    final broad =
        mac.trim().isEmpty &&
        interfaceName.trim().isEmpty &&
        ssidRegexp.trim().isEmpty &&
        signalRange.trim().isEmpty;
    if (action == 'reject' && broad) {
      issues.add(
        const WifiSafetyIssue(
          code: 'broad-reject',
          message:
              'Cette règle de rejet ne limite ni MAC, interface, SSID ni signal et peut refuser tous les clients concernés.',
          critical: true,
        ),
      );
    }
    if (action == 'query-radius') {
      issues.add(
        const WifiSafetyIssue(
          code: 'radius',
          message:
              'query-radius exige une configuration RADIUS opérationnelle et cohérente.',
        ),
      );
    }
    return issues;
  }

  static List<WifiSafetyIssue> provisioning({
    required String action,
    required String radioMac,
    required String supportedBands,
    required String identityRegexp,
    required String masterConfiguration,
  }) {
    final issues = <WifiSafetyIssue>[];
    final broad =
        radioMac.trim().isEmpty &&
        supportedBands.trim().isEmpty &&
        identityRegexp.trim().isEmpty;
    if (broad && action != 'none') {
      issues.add(
        const WifiSafetyIssue(
          code: 'broad-provisioning',
          message:
              'Cette règle de provisioning est très générale. Placée trop haut, elle peut capturer tous les CAPs avant les règles suivantes.',
          critical: true,
        ),
      );
    }
    if (action.startsWith('create-') && masterConfiguration.trim().isEmpty) {
      issues.add(
        const WifiSafetyIssue(
          code: 'master-required',
          message: 'Une action create-* nécessite une Master Configuration.',
          critical: true,
        ),
      );
    }
    return issues;
  }
}
