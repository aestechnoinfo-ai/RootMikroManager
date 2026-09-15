import 'voucher_paper_format.dart';

class VoucherPrintDensityPolicy {
  const VoucherPrintDensityPolicy();

  int effectivePerPage(VoucherPaperFormat format, int requested) {
    final safe = requested.clamp(1, 50);
    if (format == VoucherPaperFormat.thermal58 ||
        format == VoucherPaperFormat.thermal80) {
      return safe.clamp(1, 2);
    }
    return safe;
  }

  bool shouldRenderQr({
    required VoucherPaperFormat format,
    required int ticketsPerPage,
    required bool qrEnabled,
  }) {
    if (!qrEnabled) return false;
    final density = effectivePerPage(format, ticketsPerPage);
    return density < 40;
  }

  List<String> recommendations({
    required VoucherPaperFormat format,
    required int ticketsPerPage,
    required bool qrEnabled,
  }) {
    final density = effectivePerPage(format, ticketsPerPage);
    final out = <String>[];
    if (format == VoucherPaperFormat.thermal58 ||
        format == VoucherPaperFormat.thermal80) {
      if (ticketsPerPage > 2) {
        out.add('Le format thermique est limité à 2 tickets par page.');
      }
    }
    if (qrEnabled && density > 30 && density < 40) {
      out.add(
        'QR encore possible, mais 30 tickets/page ou moins est recommandé.',
      );
    }
    if (qrEnabled && density >= 40) {
      out.add('QR masqué automatiquement à partir de 40 tickets/page.');
    }
    if (density >= 40) {
      out.add('Densité élevée : valider la lisibilité sur papier réel.');
    }
    return out;
  }
}
