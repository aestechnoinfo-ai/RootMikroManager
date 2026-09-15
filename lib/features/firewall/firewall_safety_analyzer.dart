class FirewallSafetyIssue {
  final String code;
  final String message;
  final bool critical;
  const FirewallSafetyIssue({
    required this.code,
    required this.message,
    this.critical = false,
  });
}

class FirewallSafetyAnalyzer {
  const FirewallSafetyAnalyzer._();

  static List<FirewallSafetyIssue> filterRule({
    required String chain,
    required String action,
    required String protocol,
    required String srcAddress,
    required String dstPort,
    required String inInterface,
    required String connectionState,
  }) {
    final issues = <FirewallSafetyIssue>[];
    final broad = srcAddress.trim().isEmpty && inInterface.trim().isEmpty;
    if (chain == 'input' && (action == 'drop' || action == 'reject') && broad) {
      issues.add(
        const FirewallSafetyIssue(
          code: 'broad-input-block',
          message:
              'Une règle input de blocage sans source ni interface peut couper WinBox/API/SSH et l’accès distant au routeur.',
          critical: true,
        ),
      );
    }
    if (chain == 'input' &&
        action == 'accept' &&
        broad &&
        dstPort.trim().isEmpty) {
      issues.add(
        const FirewallSafetyIssue(
          code: 'broad-input-accept',
          message:
              'Cette règle accepte largement du trafic destiné au routeur. Restreignez source, interface, protocole ou ports.',
        ),
      );
    }
    if (action == 'fasttrack-connection') {
      if (chain != 'forward') {
        issues.add(
          const FirewallSafetyIssue(
            code: 'fasttrack-chain',
            message:
                'FastTrack est normalement utilisé dans la chaîne forward.',
            critical: true,
          ),
        );
      }
      if (!connectionState.contains('established') ||
          !connectionState.contains('related')) {
        issues.add(
          const FirewallSafetyIssue(
            code: 'fasttrack-state',
            message:
                'FastTrack est généralement limité aux connexions established,related.',
          ),
        );
      }
      issues.add(
        const FirewallSafetyIssue(
          code: 'fasttrack-bypass',
          message:
              'FastTrack peut contourner firewall slow-path, queues, IPsec, Hotspot et VRF assignment. Vérifiez les exceptions placées avant cette règle.',
        ),
      );
    }
    if ((dstPort.trim().isNotEmpty) &&
        protocol != 'tcp' &&
        protocol != 'udp' &&
        protocol != 'sctp') {
      issues.add(
        const FirewallSafetyIssue(
          code: 'port-protocol',
          message:
              'Les ports exigent normalement un protocole TCP/UDP/SCTP compatible.',
          critical: true,
        ),
      );
    }
    return issues;
  }

  static List<FirewallSafetyIssue> natRule({
    required String chain,
    required String action,
    required String protocol,
    required String dstPort,
    required String toAddresses,
    required String toPorts,
  }) {
    final issues = <FirewallSafetyIssue>[];
    if ((action == 'dst-nat' || action == 'redirect') &&
        chain != 'dstnat' &&
        chain != 'input' &&
        chain != 'output') {
      issues.add(
        const FirewallSafetyIssue(
          code: 'dstnat-chain',
          message:
              'Cette action de destination NAT paraît incompatible avec la chaîne choisie.',
          critical: true,
        ),
      );
    }
    if ((action == 'src-nat' || action == 'masquerade') &&
        chain != 'srcnat' &&
        chain != 'output') {
      issues.add(
        const FirewallSafetyIssue(
          code: 'srcnat-chain',
          message:
              'Cette action de source NAT paraît incompatible avec la chaîne choisie.',
          critical: true,
        ),
      );
    }
    if (action == 'dst-nat' && toAddresses.trim().isEmpty) {
      issues.add(
        const FirewallSafetyIssue(
          code: 'dstnat-target',
          message:
              'dst-nat nécessite normalement une destination to-addresses.',
          critical: true,
        ),
      );
    }
    if ((dstPort.trim().isNotEmpty || toPorts.trim().isNotEmpty) &&
        protocol != 'tcp' &&
        protocol != 'udp') {
      issues.add(
        const FirewallSafetyIssue(
          code: 'nat-port-protocol',
          message: 'Les ports NAT nécessitent généralement TCP ou UDP.',
          critical: true,
        ),
      );
    }
    return issues;
  }

  static List<FirewallSafetyIssue> mangleRule({
    required String action,
    required String chain,
    required String newMark,
  }) {
    final issues = <FirewallSafetyIssue>[];
    if (action.startsWith('mark-') && newMark.trim().isEmpty) {
      issues.add(
        const FirewallSafetyIssue(
          code: 'mark-empty',
          message: 'Une action de marquage nécessite un New Mark.',
          critical: true,
        ),
      );
    }
    if (action == 'mark-routing' && chain == 'input') {
      issues.add(
        const FirewallSafetyIssue(
          code: 'routing-mark-input',
          message:
              'Un routing mark dans input mérite une vérification spécifique : il peut affecter les réponses émises par le routeur.',
        ),
      );
    }
    return issues;
  }

  static bool dynamicOrDummy(Map<String, String> row) =>
      row['dynamic'] == 'yes' ||
      row['dynamic'] == 'true' ||
      row['dummy'] == 'yes' ||
      row['dummy'] == 'true';
}
