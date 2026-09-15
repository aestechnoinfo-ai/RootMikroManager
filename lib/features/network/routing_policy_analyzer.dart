class RoutingPolicyIssue {
  final String code;
  final String message;
  final bool critical;
  const RoutingPolicyIssue({
    required this.code,
    required this.message,
    this.critical = false,
  });
}

class RoutingPolicyAnalyzer {
  const RoutingPolicyAnalyzer._();

  static List<RoutingPolicyIssue> ipv4Route({
    required String destination,
    required String gateway,
    required String table,
    required int distance,
    required int scope,
    required int targetScope,
    required String checkGateway,
  }) {
    final issues = <RoutingPolicyIssue>[];
    if (destination == '0.0.0.0/0' && table == 'main') {
      issues.add(
        const RoutingPolicyIssue(
          code: 'main-default',
          message:
              'Cette route par défaut modifie le chemin Internet et peut affecter l’accès de management.',
          critical: true,
        ),
      );
    }
    if (gateway.contains(',') && checkGateway != 'none') {
      issues.add(
        const RoutingPolicyIssue(
          code: 'ecmp-health',
          message:
              'Route ECMP détectée : vérifiez la joignabilité et le suivi de chaque next-hop.',
        ),
      );
    }
    if (targetScope >= scope) {
      issues.add(
        const RoutingPolicyIssue(
          code: 'scope-order',
          message:
              'target-scope devrait rester inférieur au scope pour éviter des résolutions récursives inattendues.',
          critical: true,
        ),
      );
    }
    if (distance > 1) {
      issues.add(
        RoutingPolicyIssue(
          code: 'backup-distance',
          message:
              'Distance $distance : cette route sera moins prioritaire qu’une route équivalente de distance inférieure.',
        ),
      );
    }
    return issues;
  }

  static List<RoutingPolicyIssue> rule({
    required String action,
    required String source,
    required String destination,
    required String table,
  }) {
    final issues = <RoutingPolicyIssue>[];
    final broad = source.trim().isEmpty && destination.trim().isEmpty;
    if (broad) {
      issues.add(
        const RoutingPolicyIssue(
          code: 'broad-rule',
          message:
              'Cette règle ne limite ni source ni destination et peut donc s’appliquer à presque tout le trafic.',
          critical: true,
        ),
      );
    }
    if (action == 'lookup-only-in-table' && table == 'main') {
      issues.add(
        const RoutingPolicyIssue(
          code: 'strict-main',
          message:
              'lookup-only-in-table sur main interdit tout fallback vers une autre table.',
        ),
      );
    }
    if (action == 'drop' || action == 'unreachable') {
      issues.add(
        RoutingPolicyIssue(
          code: 'blocking-rule',
          message:
              'L’action $action peut bloquer le trafic de management si le périmètre est trop large.',
          critical: broad,
        ),
      );
    }
    return issues;
  }

  static List<RoutingPolicyIssue> tableDelete({
    required String name,
    required List<Map<String, String>> ipv4Routes,
    required List<Map<String, String>> ipv6Routes,
    required List<Map<String, String>> rules,
  }) {
    if (name == 'main') {
      return const [
        RoutingPolicyIssue(
          code: 'main-protected',
          message: 'La table main est protégée.',
          critical: true,
        ),
      ];
    }
    final refs = <String>[];
    if (ipv4Routes.any((r) => r['routing-table'] == name))
      refs.add('routes IPv4');
    if (ipv6Routes.any((r) => r['routing-table'] == name))
      refs.add('routes IPv6');
    if (rules.any((r) => r['table'] == name)) refs.add('routing rules');
    if (refs.isEmpty) return const [];
    return [
      RoutingPolicyIssue(
        code: 'table-referenced',
        message:
            'La table $name est encore référencée par : ${refs.join(', ')}.',
        critical: true,
      ),
    ];
  }
}
