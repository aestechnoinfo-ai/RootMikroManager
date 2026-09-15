import 'dart:async';

import 'network_binding_service.dart';
import 'mndp_scanner.dart';

class CancellationToken {
  final _cancelledSignal = Completer<void>();
  Future<void> get whenCancelled => _cancelledSignal.future;
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() {
    _cancelled = true;
    if (!_cancelledSignal.isCompleted) _cancelledSignal.complete();
  }

  void throwIfCancelled() {
    if (_cancelled) throw const ScanCancelledException();
  }
}

class ScanCancelledException implements Exception {
  const ScanCancelledException();
  @override
  String toString() => 'Scan annulé';
}

enum ScanHostStatus { pending, scanning, online, offline, authError }

class ScannedHost {
  final String ip;
  final String macAddress;
  final String identity;
  final String boardName;
  final List<int> openPorts;
  final List<String> protocols;
  final ScanHostStatus status;
  final int attempts;

  const ScannedHost({
    required this.ip,
    this.macAddress = '',
    this.identity = '',
    this.boardName = '',
    required this.openPorts,
    this.protocols = const [],
    this.status = ScanHostStatus.online,
    this.attempts = 1,
  });

  bool get likelyMikrotik =>
      openPorts.isNotEmpty || macAddress.isNotEmpty || boardName.isNotEmpty;
  String get hardwareKey => macAddress.trim().toUpperCase();
  bool get useTls => openPorts.contains(8729);
  int? get preferredApiPort =>
      openPorts.where((port) => port != 8291).firstOrNull;
}

class IpScannerService {
  static const defaultPorts = [8728, 8729, 8291];
  static const _officialHardwareImages = <String, String>{
    'rb951g-2hnd':
        'https://cdn.mikrotik.com/web-assets/rb_images/903_hi_res.png',
    'hap ac2': 'https://cdn.mikrotik.com/web-assets/rb_images/1468_hi_res.png',
    'hap ac²': 'https://cdn.mikrotik.com/web-assets/rb_images/1468_hi_res.png',
    'hap ax2': 'https://cdn.mikrotik.com/web-assets/rb_images/2203_hi_res.png',
    'hap ax²': 'https://cdn.mikrotik.com/web-assets/rb_images/2203_hi_res.png',
    'hap ax3': 'https://cdn.mikrotik.com/web-assets/rb_images/2211_hi_res.png',
    'hap ax³': 'https://cdn.mikrotik.com/web-assets/rb_images/2211_hi_res.png',
    'rb4011igs+rm':
        'https://cdn.mikrotik.com/web-assets/rb_images/1633_hi_res.png',
    'rb5009ug+s+in':
        'https://cdn.mikrotik.com/web-assets/rb_images/2065_hi_res.png',
  };

  static String? officialHardwareImageUrl(String boardName) {
    final normalized = boardName
        .trim()
        .toLowerCase()
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return null;
    // Exact matching is intentional. Product names such as hAP ac, hAP ac
    // lite, hAP ac lite TC and hAP ac2 are distinct pieces of hardware.
    final canonical = normalized.replaceAll('²', '2').replaceAll('³', '3');
    return _officialHardwareImages.entries
        .where(
          (entry) =>
              entry.key
                  .replaceAll('²', '2')
                  .replaceAll('³', '3')
                  .toLowerCase() ==
              canonical,
        )
        .map((entry) => entry.value)
        .firstOrNull;
  }

  final NetworkBindingService networkBinding;

  IpScannerService({NetworkBindingService? networkBinding})
    : networkBinding = networkBinding ?? NetworkBindingService();

  Future<ScannedHost> probeHost(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 15),
    int retries = 5,
    CancellationToken? cancellationToken,
  }) async {
    final token = cancellationToken ?? CancellationToken();
    final cappedRetries = retries.clamp(1, 5);
    for (var attempt = 1; attempt <= cappedRetries; attempt++) {
      token.throwIfCancelled();
      try {
        final open = await networkBinding.probeTcp(
          host,
          port,
          timeout: timeout,
        );
        if (open) {
          return ScannedHost(
            ip: host,
            openPorts: [port],
            protocols: const ['TCP'],
            attempts: attempt,
          );
        }
      } catch (_) {
        token.throwIfCancelled();
      }
      if (attempt < cappedRetries) {
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
      }
    }
    return ScannedHost(
      ip: host,
      openPorts: const [],
      status: ScanHostStatus.offline,
      attempts: cappedRetries,
    );
  }

  Future<List<ScannedHost>> scan24(
    String baseAddress, {
    List<int> ports = defaultPorts,
    Duration timeout = const Duration(seconds: 15),
    int maxConcurrency = 32,
    int retries = 5,
    CancellationToken? cancellationToken,
  }) {
    final parts = baseAddress.trim().split('.');
    if (parts.length != 4) {
      throw const FormatException(
        'Adresse IPv4 invalide. Exemple : 192.168.88.1',
      );
    }
    return scanCidr(
      '${parts[0]}.${parts[1]}.${parts[2]}.0/24',
      ports: ports,
      timeout: timeout,
      maxConcurrency: maxConcurrency,
      retries: retries,
      cancellationToken: cancellationToken,
    );
  }

  Future<List<ScannedHost>> scanCidr(
    String cidr, {
    List<int> ports = defaultPorts,
    Duration timeout = const Duration(seconds: 15),
    int maxConcurrency = 32,
    int maxHosts = 4096,
    int retries = 5,
    CancellationToken? cancellationToken,
  }) => scanCidrStream(
    cidr,
    ports: ports,
    timeout: timeout,
    maxConcurrency: maxConcurrency,
    maxHosts: maxHosts,
    retries: retries,
    cancellationToken: cancellationToken,
  ).toList();

  Stream<ScannedHost> scanCidrStream(
    String cidr, {
    List<int> ports = defaultPorts,
    Duration timeout = const Duration(seconds: 15),
    int maxConcurrency = 32,
    int maxHosts = 4096,
    int retries = 5,
    CancellationToken? cancellationToken,
  }) async* {
    final range = _parseCidr(cidr);
    if (range.totalHosts > maxHosts) {
      throw FormatException(
        'La plage $cidr contient ${range.totalHosts} adresses. '
        'Limite de sécurité : $maxHosts adresses par scan.',
      );
    }
    final token = cancellationToken ?? CancellationToken();
    final state = await networkBinding.state();
    final bindVpn = state.vpn && state.cellular;
    final addresses = <String>[
      for (var value = range.firstHost; value <= range.lastHost; value++)
        _intToIpv4(value),
    ];
    var cursor = 0;
    final controller = StreamController<ScannedHost>();

    Future<void> worker() async {
      while (!token.isCancelled) {
        final index = cursor++;
        if (index >= addresses.length) return;
        final ip = addresses[index];
        final opened = <int>[];
        var usedAttempts = 0;
        for (var attempt = 1; attempt <= retries.clamp(1, 5); attempt++) {
          token.throwIfCancelled();
          usedAttempts = attempt;
          final remainingPorts = ports.toSet().difference(opened.toSet());
          final checks = await Future.wait(
            remainingPorts.map((port) async {
              try {
                final open = await networkBinding.probeTcp(
                  ip,
                  port,
                  timeout: timeout,
                  bindVpn: bindVpn,
                );
                return open ? port : null;
              } catch (_) {
                return null;
              }
            }),
          );
          opened.addAll(checks.whereType<int>());
          if (opened.isNotEmpty) break;
          if (attempt < retries) {
            await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
          }
        }
        if (!token.isCancelled && opened.isNotEmpty) {
          controller.add(
            ScannedHost(
              ip: ip,
              openPorts: opened,
              protocols: const ['TCP'],
              attempts: usedAttempts,
            ),
          );
        }
      }
    }

    final workers = List.generate(maxConcurrency.clamp(1, 64), (_) => worker());
    unawaited(Future.wait(workers).whenComplete(controller.close));
    yield* controller.stream;
  }

  Stream<ScannedHost> discoverMndp({
    Duration duration = const Duration(seconds: 15),
    CancellationToken? cancellationToken,
  }) async* {
    final token = cancellationToken ?? CancellationToken();
    final seenMacs = <String>{};
    await for (final row in const MndpScanner().scan(
      duration: duration,
      cancelled: token.whenCancelled,
    )) {
      if (token.isCancelled) return;
      final mac = (row['mac-address'] ?? '').toUpperCase();
      if (mac.isEmpty || !seenMacs.add(mac)) continue;
      final address = row['address'] ?? '';
      yield ScannedHost(
        ip: address.contains(':') ? '' : address,
        macAddress: mac,
        identity: row['identity'] ?? '',
        boardName: row['board'] ?? '',
        openPorts: const [],
        protocols: const ['MNDP'],
      );
    }
  }

  _Ipv4Range _parseCidr(String cidr) {
    final parts = cidr.trim().split('/');
    if (parts.length != 2) {
      throw const FormatException('CIDR invalide. Exemple : 10.10.10.0/24');
    }
    final prefix = int.tryParse(parts[1]);
    if (prefix == null || prefix < 8 || prefix > 32) {
      throw const FormatException('Préfixe CIDR supporté : /8 à /32.');
    }
    final address = _ipv4ToInt(parts[0]);
    final mask = (0xffffffff << (32 - prefix)) & 0xffffffff;
    final network = address & mask;
    final broadcast = network | (~mask & 0xffffffff);
    if (prefix == 32) return _Ipv4Range(network, network);
    if (prefix == 31) return _Ipv4Range(network, broadcast);
    return _Ipv4Range(network + 1, broadcast - 1);
  }

  int _ipv4ToInt(String ip) {
    final octets = ip.trim().split('.');
    if (octets.length != 4) throw FormatException('IPv4 invalide : $ip');
    var value = 0;
    for (final raw in octets) {
      final octet = int.tryParse(raw);
      if (octet == null || octet < 0 || octet > 255) {
        throw FormatException('IPv4 invalide : $ip');
      }
      value = (value << 8) | octet;
    }
    return value;
  }

  String _intToIpv4(int value) => [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ].join('.');
}

class _Ipv4Range {
  final int firstHost;
  final int lastHost;
  const _Ipv4Range(this.firstHost, this.lastHost);
  int get totalHosts => lastHost >= firstHost ? lastHost - firstHost + 1 : 0;
}
