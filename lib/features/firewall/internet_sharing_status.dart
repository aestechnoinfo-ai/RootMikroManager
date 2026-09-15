import 'internet_sharing_rule.dart';

class InternetSharingStatus {
  final int protectedInterfaces;
  final int enabledRules;
  final int disabledRules;

  const InternetSharingStatus({
    required this.protectedInterfaces,
    required this.enabledRules,
    required this.disabledRules,
  });

  factory InternetSharingStatus.fromRules(List<InternetSharingRule> rules) {
    final enabled = rules.where((e) => e.enabled).length;
    return InternetSharingStatus(
      protectedInterfaces: rules.length,
      enabledRules: enabled,
      disabledRules: rules.length - enabled,
    );
  }
}
