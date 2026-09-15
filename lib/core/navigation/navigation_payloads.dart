import '../../features/vouchers/voucher_batch_action_result.dart';
import '../../data/models/router_model.dart';
import '../../features/network/wifi_profile_kind.dart';
import '../../features/network/wifi_config_backend.dart';
import '../../features/discovery/discovery_candidate.dart';
import '../../features/vouchers/voucher_generation_batch_result.dart';
import '../../features/vouchers/voucher_print_layout.dart';
import '../../features/vouchers/voucher_template_settings.dart';

class HotspotUserPayload {
  final Map<String, String> user;
  const HotspotUserPayload(this.user);
}

class OptionalRowPayload {
  final Map<String, String>? row;
  const OptionalRowPayload([this.row]);
}

class HotspotAddUserPayload {
  final String? initialProfile;
  const HotspotAddUserPayload({this.initialProfile});
}

class HotspotHostPayload {
  final Map<String, String> host;
  const HotspotHostPayload(this.host);
}

class VoucherPrintPayload {
  final List<Map<String, String>> vouchers;
  final VoucherPrintLayout layout;
  final VoucherTemplateSettings templateSettings;

  const VoucherPrintPayload({
    required this.vouchers,
    required this.layout,
    required this.templateSettings,
  });
}

class VoucherGenerationResultPayload {
  final VoucherGenerationBatchResult result;
  const VoucherGenerationResultPayload(this.result);
}

class PppActivePayload {
  final Map<String, String> row;
  const PppActivePayload(this.row);
}

class RequiredRowPayload {
  final Map<String, String> row;
  const RequiredRowPayload(this.row);
}

class QueueDetailPayload {
  final String title;
  final Map<String, String> row;
  const QueueDetailPayload({required this.title, required this.row});
}

class WireGuardPeersPayload {
  final String interfaceName;
  const WireGuardPeersPayload(this.interfaceName);
}

class DiscoveryCandidatePayload {
  final DiscoveryCandidate candidate;
  const DiscoveryCandidatePayload(this.candidate);
}

class FirewallRulePayload {
  final String path;
  final String title;
  final Map<String, String>? row;
  const FirewallRulePayload({
    required this.path,
    required this.title,
    this.row,
  });
}

class FirewallAdvancedRulePayload {
  final String path;
  final Map<String, String>? row;
  const FirewallAdvancedRulePayload({required this.path, this.row});
}

class WifiAccessRulePayload {
  final WifiConfigBackend backend;
  final Map<String, String>? row;
  const WifiAccessRulePayload({required this.backend, this.row});
}

class WifiProfilePayload {
  final WifiProfileKind kind;
  final Map<String, String>? row;
  const WifiProfilePayload({required this.kind, this.row});
}

class RouterConnectionPayload {
  final RouterModel router;
  const RouterConnectionPayload(this.router);
}

class VoucherBatchLifecycleResultPayload {
  final String title;
  final VoucherBatchActionResult result;
  const VoucherBatchLifecycleResultPayload({
    required this.title,
    required this.result,
  });
}

class WireGuardPeerEditPayload {
  final String interfaceName;
  final Map<String, String>? row;
  const WireGuardPeerEditPayload({required this.interfaceName, this.row});
}

class InterfaceMonitorPayload {
  final String interfaceName;
  const InterfaceMonitorPayload(this.interfaceName);
}
