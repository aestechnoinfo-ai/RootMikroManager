class DhcpDnsSafetyIssue {
  final String code;
  final String message;
  final bool critical;

  const DhcpDnsSafetyIssue({
    required this.code,
    required this.message,
    this.critical = false,
  });
}

class DhcpDnsSafetyAnalyzer {
  const DhcpDnsSafetyAnalyzer._();

  static List<DhcpDnsSafetyIssue> dhcpServer({
    required String interfaceName,
    required String addressPool,
    required String relay,
    required List<Map<String, String>> servers,
    String? currentId,
  }) {
    final issues = <DhcpDnsSafetyIssue>[];
    if (interfaceName.trim().isEmpty) {
      issues.add(
        const DhcpDnsSafetyIssue(
          code: 'interface-empty',
          message: 'Aucune interface DHCP sélectionnée.',
          critical: true,
        ),
      );
    }
    final duplicate = servers.any((row) {
      if (row['.id'] == currentId) return false;
      final disabled = row['disabled'] == 'yes' || row['disabled'] == 'true';
      return !disabled && row['interface'] == interfaceName;
    });
    if (duplicate) {
      issues.add(
        DhcpDnsSafetyIssue(
          code: 'duplicate-interface',
          message:
              'Un autre serveur DHCP actif utilise déjà l’interface $interfaceName.',
          critical: true,
        ),
      );
    }
    if (addressPool == 'static-only') {
      issues.add(
        const DhcpDnsSafetyIssue(
          code: 'static-only',
          message:
              'Le serveur est en static-only : seuls les baux statiques recevront une adresse.',
        ),
      );
    }
    if (relay.trim().isNotEmpty && relay.trim() != '0.0.0.0') {
      issues.add(
        const DhcpDnsSafetyIssue(
          code: 'relay',
          message:
              'Un DHCP Relay est configuré. Vérifiez qu’il correspond bien au réseau distant attendu.',
        ),
      );
    }
    return issues;
  }

  static List<DhcpDnsSafetyIssue> dnsResolver({
    required bool allowRemoteRequests,
    required String dohServer,
    required bool verifyDohCertificate,
  }) {
    final issues = <DhcpDnsSafetyIssue>[];
    if (allowRemoteRequests) {
      issues.add(
        const DhcpDnsSafetyIssue(
          code: 'remote-dns',
          message:
              'Le routeur répondra aux requêtes DNS des clients. Le firewall doit limiter TCP/UDP 53 aux réseaux de confiance.',
          critical: true,
        ),
      );
    }
    if (dohServer.trim().isNotEmpty && !verifyDohCertificate) {
      issues.add(
        const DhcpDnsSafetyIssue(
          code: 'doh-cert',
          message: 'DoH est configuré sans vérification du certificat TLS.',
          critical: true,
        ),
      );
    }
    return issues;
  }
}
