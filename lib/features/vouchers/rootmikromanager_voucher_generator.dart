import 'dart:math';

class RootMikroManagerVoucherGenerator {
  final Random _random;

  RootMikroManagerVoucherGenerator({Random? random})
    : _random = random ?? Random.secure();

  // Identiques aux alphabets Mikhmon : 0/1 et lettres ambiguës sont exclues.
  static const _lower = 'abcdefghijkmnprstuvwxyz';
  static const _upper = 'ABCDEFGHJKLMNPRSTUVWXYZ';
  static const _numbers = '23456789';
  static const _upperLower = 'ABCDEFGHJKLMNPRSTUVWXYZabcdefghijkmnprstuvwxyz';
  static const _numLower = '23456789abcdefghijkmnprstuvwxyz';
  static const _numUpper = '23456789ABCDEFGHJKLMNPRSTUVWXYZ';
  static const _numUpperLower =
      '23456789ABCDEFGHJKLMNPRSTUVWXYZabcdefghijkmnprstuvwxyz';

  String generate({required int length, required String characterMode}) {
    final safeLength = length.clamp(3, 8).toInt();
    final chars = switch (characterMode) {
      'lower' => _lower,
      'upper' => _upper,
      'upplow' => _upperLower,
      'mix' => _numLower,
      'mix1' => _numUpper,
      'mix2' => _numUpperLower,
      'num' => _numbers,
      _ => _numUpperLower,
    };
    return _take(chars, safeLength);
  }

  /// RootMikroManager `up`: random username using selected charset and an independent
  /// numeric password with the same configured length.
  ({String username, String password}) userPassword({
    required String prefix,
    required String suffix,
    required int length,
    required String characterMode,
  }) {
    final safeLength = length.clamp(3, 8).toInt();
    return (
      username:
          '$prefix${generate(length: safeLength, characterMode: characterMode)}$suffix',
      password: _take(_numbers, safeLength),
    );
  }

  /// RootMikroManager `vc`: username and password are identical.
  /// For lower/upper/upplow RootMikroManager reserves a numeric suffix whose size
  /// depends on the configured length; mix/num modes use the full charset.
  String voucher({
    required String prefix,
    required String suffix,
    required int length,
    required String characterMode,
  }) {
    final safeLength = length.clamp(3, 8).toInt();

    if (characterMode == 'num' ||
        characterMode == 'mix' ||
        characterMode == 'mix1' ||
        characterMode == 'mix2') {
      return '$prefix${generate(length: safeLength, characterMode: characterMode)}$suffix';
    }

    final numericLength = switch (safeLength) {
      3 => 1,
      4 || 5 => 2,
      6 || 7 => 3,
      _ => 4,
    };
    final letterLength = safeLength - numericLength;
    final letterChars = switch (characterMode) {
      'lower' => _lower,
      'upper' => _upper,
      _ => _upperLower,
    };

    return '$prefix${_take(letterChars, letterLength)}${_take(_numbers, numericLength)}$suffix';
  }

  String _take(String chars, int length) =>
      List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
}
