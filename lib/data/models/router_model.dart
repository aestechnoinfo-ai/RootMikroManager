class RouterModel {
  final int? id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String groupName;
  final String tags;
  final int? colorValue;
  final String? createdAt;
  final String macAddress;
  final String romonId;
  final bool useTls;
  final String protocols;
  final String boardName;

  const RouterModel({
    this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.groupName = 'Général',
    this.tags = '',
    this.colorValue,
    this.createdAt,
    this.macAddress = '',
    this.romonId = '',
    this.useTls = false,
    this.protocols = '',
    this.boardName = '',
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'username': username,
    'group_name': groupName,
    'tags': tags,
    'color_value': colorValue,
    'created_at': createdAt ?? DateTime.now().toIso8601String(),
    'mac_address': macAddress,
    'romon_id': romonId,
    'use_tls': useTls ? 1 : 0,
    'protocols': protocols,
    'board_name': boardName,
  };

  factory RouterModel.fromMap(Map<String, Object?> map) => RouterModel(
    id: map['id'] as int?,
    name: (map['name'] ?? '').toString(),
    host: (map['host'] ?? '').toString(),
    port: (map['port'] as num?)?.toInt() ?? 8728,
    username: (map['username'] ?? '').toString(),
    groupName: (map['group_name'] ?? 'Général').toString(),
    tags: (map['tags'] ?? '').toString(),
    colorValue: (map['color_value'] as num?)?.toInt(),
    createdAt: map['created_at']?.toString(),
    macAddress: (map['mac_address'] ?? '').toString(),
    romonId: (map['romon_id'] ?? '').toString(),
    useTls: map['use_tls'] == 1 || map['use_tls'] == true,
    protocols: (map['protocols'] ?? '').toString(),
    boardName: (map['board_name'] ?? '').toString(),
  );
}
