import '../routeros/routeros_service.dart';
import 'ip_scanner_service.dart';

class VpnCandidateNetwork {
  final String source;
  final String name;
  final String cidr;
  final String? interfaceName;

  const VpnCandidateNetwork({
    required this.source,
    required this.name,
    required this.cidr,
    this.interfaceName,
  });
}

class VpnDiscoveryResult {
  final List<VpnCandidateNetwork> networks;
  final List<Map<String, String>> wireGuardInterfaces;
  final List<Map<String, String>> wireGuardPeers;
  final List<Map<String, String>> zeroTierInterfaces;
  final Map<String, String> backToHome;
  final List<Map<String, String>> backToHomeUsers;

  const VpnDiscoveryResult({
    required this.networks,
    required this.wireGuardInterfaces,
    required this.wireGuardPeers,
    required this.zeroTierInterfaces,
    required this.backToHome,
    required this.backToHomeUsers,
  });
}

class VpnDiscoveryService {
  final RouterOsService routerOs;
  final IpScannerService scanner;

  const VpnDiscoveryService({required this.routerOs, required this.scanner});

  Future<VpnDiscoveryResult> inspectRouterVpns() async {
    final wireGuardInterfaces = await _safeList(routerOs.wireGuardInterfaces);
    final wireGuardPeers = await _safeList(routerOs.wireGuardPeers);
    final zeroTierInterfaces = await _safeList(routerOs.zeroTierInterfaces);
    final backToHome = await _safeMap(routerOs.backToHomeStatus);
    final backToHomeUsers = await _safeList(routerOs.backToHomeUsers);
    final addresses = await _safeList(routerOs.ipAddresses);

    final networks = <VpnCandidateNetwork>[];

    for (final address in addresses) {
      final cidr = _networkFromAddress(address['address']);
      if (cidr == null) continue;

      final interfaceName = address['interface'] ?? '';
      final lower = interfaceName.toLowerCase();

      String? source;
      if (lower.contains('wireguard') ||
          lower.contains('back-to-home') ||
          lower.contains('back_to_home') ||
          lower.contains('bth')) {
        source = 'WireGuard / BackToHome';
      } else if (lower.contains('zero') || lower.startsWith('zt')) {
        source = 'ZeroTier';
      }

      if (source != null) {
        networks.add(
          VpnCandidateNetwork(
            source: source,
            name: interfaceName.isEmpty ? source : interfaceName,
            cidr: cidr,
            interfaceName: interfaceName,
          ),
        );
      }
    }

    for (final peer in wireGuardPeers) {
      for (final token in _splitAddresses(
        peer['allowed-address'] ?? peer['allowed-addresses'],
      )) {
        final normalized = _normalizeCidr(token);
        if (normalized == null) continue;
        networks.add(
          VpnCandidateNetwork(
            source: 'WireGuard peer',
            name: peer['name'] ?? peer['comment'] ?? 'WireGuard peer',
            cidr: normalized,
            interfaceName: peer['interface'],
          ),
        );
      }
    }

    for (final user in backToHomeUsers) {
      for (final token in _splitAddresses(
        user['client-address'] ?? user['client-addresss'],
      )) {
        final normalized = _normalizeCidr(token);
        if (normalized == null) continue;
        networks.add(
          VpnCandidateNetwork(
            source: 'BackToHome',
            name: user['name'] ?? 'BTH user',
            cidr: normalized,
            interfaceName: backToHome['vpn-interface'],
          ),
        );
      }
    }

    final unique = <String, VpnCandidateNetwork>{};
    for (final network in networks) {
      unique['${network.source}|${network.cidr}'] = network;
    }

    return VpnDiscoveryResult(
      networks: unique.values.toList(),
      wireGuardInterfaces: wireGuardInterfaces,
      wireGuardPeers: wireGuardPeers,
      zeroTierInterfaces: zeroTierInterfaces,
      backToHome: backToHome,
      backToHomeUsers: backToHomeUsers,
    );
  }

  Future<List<ScannedHost>> scanNetwork(String cidr) => scanner.scanCidr(cidr);

  Future<List<T>> _safeList<T>(Future<List<T>> Function() loader) async {
    try {
      return await loader();
    } catch (_) {
      return <T>[];
    }
  }

  Future<Map<String, String>> _safeMap(
    Future<Map<String, String>> Function() loader,
  ) async {
    try {
      return await loader();
    } catch (_) {
      return <String, String>{};
    }
  }

  Iterable<String> _splitAddresses(String? value) sync* {
    if (value == null || value.trim().isEmpty) return;

    for (final token in value.split(RegExp(r'[,; ]+'))) {
      if (token.trim().isNotEmpty) {
        yield token.trim();
      }
    }
  }

  String? _normalizeCidr(String raw) {
    final value = raw.trim();
    if (!value.contains('.')) return null;

    if (value.contains('/')) {
      final prefix = int.tryParse(value.split('/').last);
      if (prefix == null) return null;

      if (prefix >= 8 && prefix <= 32) return value;
      return null;
    }

    return '$value/32';
  }

  String? _networkFromAddress(String? value) {
    if (value == null || !value.contains('/')) return null;

    final parts = value.split('/');
    final ip = parts.first;
    final prefix = int.tryParse(parts.last);
    if (prefix == null || prefix < 8 || prefix > 30) return null;

    final octets = ip.split('.').map(int.tryParse).toList();
    if (octets.length != 4 || octets.any((e) => e == null)) return null;

    final ipInt =
        (octets[0]! << 24) |
        (octets[1]! << 16) |
        (octets[2]! << 8) |
        octets[3]!;
    final mask = (0xffffffff << (32 - prefix)) & 0xffffffff;
    final network = ipInt & mask;

    final networkIp = [
      (network >> 24) & 0xff,
      (network >> 16) & 0xff,
      (network >> 8) & 0xff,
      network & 0xff,
    ].join('.');

    return '$networkIp/$prefix';
  }
}
