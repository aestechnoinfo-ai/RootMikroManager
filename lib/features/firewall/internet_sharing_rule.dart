class InternetSharingRule {
  static const marker = 'RootMikroManager AntiSharing';

  final String id;
  final String interfaceName;
  final int ttl;
  final bool enabled;
  final String comment;

  const InternetSharingRule({
    required this.id,
    required this.interfaceName,
    required this.ttl,
    required this.enabled,
    required this.comment,
  });

  factory InternetSharingRule.fromRouterOs(Map<String, String> row) {
    final ttlRaw = (row['new-ttl'] ?? 'set:1').trim();
    final ttlValue = ttlRaw.startsWith('set:')
        ? int.tryParse(ttlRaw.substring(4)) ?? 1
        : 1;

    return InternetSharingRule(
      id: row['.id'] ?? '',
      interfaceName: row['out-interface'] ?? '',
      ttl: ttlValue,
      enabled: row['disabled'] != 'yes' && row['disabled'] != 'true',
      comment: row['comment'] ?? '',
    );
  }

  static bool isManaged(Map<String, String> row) =>
      (row['comment'] ?? '').startsWith(marker) &&
      row['chain'] == 'postrouting' &&
      row['action'] == 'change-ttl';
}
