import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/reports/rootmikromanager_sales_record.dart';
import 'package:root_mikro_manager/features/reports/sales_report_print_service.dart';

void main() {
  test(
    'un rapport de plusieurs milliers de ventes est paginé sans exception',
    () async {
      final records = List.generate(
        25000,
        (index) => RootMikroManagerSalesRecord(
          id: '*$index',
          date: '2026-09-05',
          time: '12:00:00',
          username: 'voucher-$index',
          price: '100',
          address: '',
          macAddress: '',
          validity: '3h',
          profile: 'profil-${index % 5}',
          comment: 'vente $index',
          owner: 'admin',
          source: '',
        ),
      );

      final bytes = await SalesReportPrintService.buildPdf(
        records: records,
        currency: 'FCFA',
        periodLabel: 'Toutes les ventes',
      );

      expect(bytes.length, greaterThan(10000));
      final rawPdf = latin1.decode(bytes, allowInvalid: true);
      final pageObjects = RegExp(
        r'/Type\s*/Page(?!s)',
      ).allMatches(rawPdf).length;
      // 25 000 / 35 = 715 pages de ventes, plus le résumé par profil.
      expect(pageObjects, 716);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
