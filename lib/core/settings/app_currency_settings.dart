import '../database/app_database.dart';

class AppCurrencySettings {
  AppCurrencySettings._();

  static const String key = 'app_currency';
  static const String legacyVoucherKey = 'voucher_currency';

  static Future<String> load() async {
    final db = AppDatabase.instance;
    final current = (await db.getSetting(key))?.trim();
    if (current != null && current.isNotEmpty) return current;

    final legacy = (await db.getSetting(legacyVoucherKey))?.trim();
    if (legacy != null && legacy.isNotEmpty) {
      await db.setSetting(key, legacy);
      return legacy;
    }
    return '';
  }

  static Future<void> save(String currency) async {
    final value = currency.trim();
    final db = AppDatabase.instance;
    await db.setSetting(key, value);
    await db.setSetting(legacyVoucherKey, value);
  }

  static String format(num amount, String currency, {int decimals = 2}) {
    final number = amount.toStringAsFixed(decimals);
    return currency.trim().isEmpty ? number : '$number ${currency.trim()}';
  }

  static String formatRaw(String amount, String currency) {
    final value = amount.trim().isEmpty ? '0' : amount.trim();
    return currency.trim().isEmpty ? value : '$value ${currency.trim()}';
  }
}
