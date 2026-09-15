import 'package:pdf/pdf.dart';

enum VoucherPaperFormat { printer, a4, thermal80, thermal58 }

extension VoucherPaperFormatX on VoucherPaperFormat {
  String get key => name;
  String get label => switch (this) {
    VoucherPaperFormat.printer => 'Format imprimante',
    VoucherPaperFormat.a4 => 'A4',
    VoucherPaperFormat.thermal80 => 'Thermique 80 mm',
    VoucherPaperFormat.thermal58 => 'Thermique 58 mm',
  };

  PdfPageFormat resolve(PdfPageFormat printerFormat) => switch (this) {
    VoucherPaperFormat.printer => printerFormat,
    VoucherPaperFormat.a4 => PdfPageFormat.a4,
    VoucherPaperFormat.thermal80 => PdfPageFormat(
      80 * PdfPageFormat.mm,
      120 * PdfPageFormat.mm,
    ),
    VoucherPaperFormat.thermal58 => PdfPageFormat(
      58 * PdfPageFormat.mm,
      100 * PdfPageFormat.mm,
    ),
  };

  static VoucherPaperFormat fromKey(String? value) {
    for (final e in VoucherPaperFormat.values) {
      if (e.key == value) return e;
    }
    return VoucherPaperFormat.printer;
  }
}
