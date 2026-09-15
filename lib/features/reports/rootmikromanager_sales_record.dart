class RootMikroManagerSalesRecord {
  final String id, date, time, username, price, address, macAddress;
  final String validity, profile, comment, owner, source;

  const RootMikroManagerSalesRecord({
    required this.id,
    required this.date,
    required this.time,
    required this.username,
    required this.price,
    required this.address,
    required this.macAddress,
    required this.validity,
    required this.profile,
    required this.comment,
    required this.owner,
    required this.source,
  });

  double get numericPrice => double.tryParse(price.replaceAll(',', '.')) ?? 0;

  factory RootMikroManagerSalesRecord.fromRouterOs(Map<String, String> row) {
    final parts = (row['name'] ?? '').split('-|-');
    String p(int i) => parts.length > i ? parts[i].trim() : '';
    return RootMikroManagerSalesRecord(
      id: row['.id'] ?? '',
      date: p(0),
      time: p(1),
      username: p(2),
      price: p(3),
      address: p(4),
      macAddress: p(5),
      validity: p(6),
      profile: p(7),
      comment: p(8),
      owner: row['owner'] ?? '',
      source: row['source'] ?? '',
    );
  }

  bool get isValid => username.isNotEmpty && profile.isNotEmpty;
}
