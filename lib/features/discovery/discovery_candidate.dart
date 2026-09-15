class DiscoveryCandidate {
  final String source;
  final String identity;
  final String address;
  final String macAddress;
  final String board;
  final String version;
  final String interfaceName;
  final List<int> openPorts;
  final int? hops;
  final int? cost;
  final String romonId;
  final bool useTls;
  final List<String> protocols;

  const DiscoveryCandidate({
    required this.source,
    this.identity = '',
    this.address = '',
    this.macAddress = '',
    this.board = '',
    this.version = '',
    this.interfaceName = '',
    this.openPorts = const [],
    this.hops,
    this.cost,
    this.romonId = '',
    this.useTls = false,
    this.protocols = const [],
  });

  bool get reachableByApi =>
      openPorts.contains(8728) || openPorts.contains(8729);

  bool get likelyRouterOs =>
      reachableByApi ||
      openPorts.contains(8291) ||
      board.isNotEmpty ||
      version.isNotEmpty;

  String get bestName {
    if (identity.trim().isNotEmpty) return identity.trim();
    if (address.trim().isNotEmpty) return address.trim();
    if (macAddress.trim().isNotEmpty) return macAddress.trim();
    return 'Routeur détecté';
  }

  String get preferredHost => address.trim();

  int get preferredPort => openPorts.contains(8729) ? 8729 : 8728;
}
