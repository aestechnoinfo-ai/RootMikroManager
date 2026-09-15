class RootMikroManagerProfileMetadata {
  final String validity;
  final String price;
  final String sellingPrice;
  final String lockUser;

  const RootMikroManagerProfileMetadata({
    this.validity = '',
    this.price = '0',
    this.sellingPrice = '0',
    this.lockUser = 'Disable',
  });

  factory RootMikroManagerProfileMetadata.fromProfile(
    Map<String, String> profile,
  ) {
    final onLogin = profile['on-login'] ?? '';
    if (onLogin.isEmpty) return const RootMikroManagerProfileMetadata();

    // RootMikroManager official serializes business metadata into the :put(...) prefix
    // of the Hotspot profile on-login script. generateuser.php reads indexes
    // 2, 3, 4 and 6 after splitting by comma.
    final parts = onLogin.split(',');
    if (parts.length < 7) return const RootMikroManagerProfileMetadata();

    String clean(String value) => value
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(')', '')
        .replaceAll(';', '')
        .trim();

    return RootMikroManagerProfileMetadata(
      price: clean(parts[2]).isEmpty ? '0' : clean(parts[2]),
      validity: clean(parts[3]),
      sellingPrice: clean(parts[4]).isEmpty ? '0' : clean(parts[4]),
      lockUser: clean(parts[6]).isEmpty ? 'Disable' : clean(parts[6]),
    );
  }
}
