import '../../core/database/app_database.dart';
import '../../core/settings/app_currency_settings.dart';
import 'voucher_paper_format.dart';

class VoucherTemplateSettings {
  final String hotspotName;
  final String title;
  final String currency;
  final String loginUrl;
  final String footerText;
  final int ticketsPerPage;
  final VoucherPaperFormat paperFormat;

  final bool showTitle;
  final bool showHotspotName;
  final bool showPassword;
  final bool showProfile;
  final bool showValidity;
  final bool showTimeLimit;
  final bool showDataLimit;
  final bool showPrice;
  final bool showLoginUrl;
  final bool showQr;
  final bool showNumber;
  final bool showComment;

  const VoucherTemplateSettings({
    this.hotspotName = 'Hotspot',
    this.title = 'RootMikroManager',
    this.currency = '',
    this.loginUrl = '',
    this.footerText = '',
    this.ticketsPerPage = 10,
    this.paperFormat = VoucherPaperFormat.printer,
    this.showTitle = true,
    this.showHotspotName = true,
    this.showPassword = true,
    this.showProfile = true,
    this.showValidity = true,
    this.showTimeLimit = true,
    this.showDataLimit = true,
    this.showPrice = true,
    this.showLoginUrl = true,
    this.showQr = true,
    this.showNumber = true,
    this.showComment = false,
  });

  int get safeTicketsPerPage => ticketsPerPage.clamp(1, 50).toInt();

  static bool _bool(String? value, {required bool fallback}) {
    if (value == null) return fallback;
    return value != 'false';
  }

  static Future<VoucherTemplateSettings> load() async {
    final db = AppDatabase.instance;
    final perPageRaw = await db.getSetting('voucher_tickets_per_page');
    final perPage = int.tryParse(perPageRaw ?? '') ?? 10;

    return VoucherTemplateSettings(
      hotspotName: await db.getSetting('voucher_hotspot_name') ?? 'Hotspot',
      title: await db.getSetting('voucher_title') ?? 'RootMikroManager',
      currency: await AppCurrencySettings.load(),
      loginUrl: await db.getSetting('voucher_login_url') ?? '',
      footerText: await db.getSetting('voucher_footer_text') ?? '',
      ticketsPerPage: perPage.clamp(1, 50).toInt(),
      paperFormat: VoucherPaperFormatX.fromKey(
        await db.getSetting('voucher_paper_format'),
      ),
      showTitle: _bool(
        await db.getSetting('voucher_show_title'),
        fallback: true,
      ),
      showHotspotName: _bool(
        await db.getSetting('voucher_show_hotspot_name'),
        fallback: true,
      ),
      showPassword: _bool(
        await db.getSetting('voucher_show_password'),
        fallback: true,
      ),
      showProfile: _bool(
        await db.getSetting('voucher_show_profile'),
        fallback: true,
      ),
      showValidity: _bool(
        await db.getSetting('voucher_show_validity'),
        fallback: true,
      ),
      showTimeLimit: _bool(
        await db.getSetting('voucher_show_time_limit'),
        fallback: true,
      ),
      showDataLimit: _bool(
        await db.getSetting('voucher_show_data_limit'),
        fallback: true,
      ),
      showPrice: _bool(
        await db.getSetting('voucher_show_price'),
        fallback: true,
      ),
      showLoginUrl: _bool(
        await db.getSetting('voucher_show_login_url'),
        fallback: true,
      ),
      showQr: _bool(await db.getSetting('voucher_show_qr'), fallback: true),
      showNumber: _bool(
        await db.getSetting('voucher_show_number'),
        fallback: true,
      ),
      showComment: _bool(
        await db.getSetting('voucher_show_comment'),
        fallback: false,
      ),
    );
  }

  Future<void> save() async {
    final db = AppDatabase.instance;
    await db.setSetting('voucher_hotspot_name', hotspotName);
    await db.setSetting('voucher_title', title);
    await AppCurrencySettings.save(currency);
    await db.setSetting('voucher_login_url', loginUrl);
    await db.setSetting('voucher_footer_text', footerText);
    await db.setSetting('voucher_tickets_per_page', '${safeTicketsPerPage}');
    await db.setSetting('voucher_paper_format', paperFormat.key);
    await db.setSetting('voucher_show_title', '$showTitle');
    await db.setSetting('voucher_show_hotspot_name', '$showHotspotName');
    await db.setSetting('voucher_show_password', '$showPassword');
    await db.setSetting('voucher_show_profile', '$showProfile');
    await db.setSetting('voucher_show_validity', '$showValidity');
    await db.setSetting('voucher_show_time_limit', '$showTimeLimit');
    await db.setSetting('voucher_show_data_limit', '$showDataLimit');
    await db.setSetting('voucher_show_price', '$showPrice');
    await db.setSetting('voucher_show_login_url', '$showLoginUrl');
    await db.setSetting('voucher_show_qr', '$showQr');
    await db.setSetting('voucher_show_number', '$showNumber');
    await db.setSetting('voucher_show_comment', '$showComment');
    await db.log('voucher.template.updated');
  }

  static Future<void> reset() async {
    await const VoucherTemplateSettings().save();
  }
}
