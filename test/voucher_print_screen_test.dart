import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_print_layout.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_paper_format.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_print_screen.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_print_service.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_template_settings.dart';

void main() {
  test('voucher PDF can be generated for every layout', () async {
    const voucher = {
      'username': 'RMM-A7K926',
      'password': 'secret',
      'profile': '1H-2M',
      'validity': '1h',
      'selling-price': '500',
      'limit-uptime': '1h',
      'limit-bytes-total': '1073741824',
      'comment': 'Promo',
    };

    for (final layout in VoucherPrintLayout.values) {
      final bytes = await VoucherPrintService.buildPdf(
        const [voucher],
        PdfPageFormat.a4,
        layout: layout,
        settings: const VoucherTemplateSettings(
          loginUrl: 'https://wifi.example.test/login',
        ),
      );
      expect(bytes, isNotEmpty, reason: 'layout ${layout.name}');
    }
  });

  test('la grille compacte A4 accepte 5 colonnes et 10 rangées', () async {
    final vouchers = List.generate(
      50,
      (index) => {
        'username': 'code${index + 1}',
        'password': 'pass${index + 1}',
        'validity': '1d',
        'selling-price': '100',
        'limit-uptime': '2h',
      },
    );
    for (final layout in [
      VoucherPrintLayout.mikhmonCode,
      VoucherPrintLayout.mikhmonCredentials,
    ]) {
      final bytes = await VoucherPrintService.buildPdf(
        vouchers,
        PdfPageFormat.a4,
        layout: layout,
        settings: const VoucherTemplateSettings(
          hotspotName: 'AES Tech wifizone',
          footerText: 'Par AESOLTEC AFRIQUE',
          currency: 'CFA',
          ticketsPerPage: 50,
          paperFormat: VoucherPaperFormat.a4,
        ),
      );
      expect(bytes, isNotEmpty);
    }
  });

  testWidgets('ticket preview does not overflow on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: VoucherPrintScreen(
          vouchers: [
            {
              'username': 'RMM-A7K926',
              'password': 'secret',
              'profile': '1H-2M',
              'validity': '1h',
              'selling-price': '500',
              'limit-uptime': '1h',
              'limit-bytes-total': '1073741824',
              'comment': 'Promo',
            },
          ],
          layout: VoucherPrintLayout.standard,
          templateSettings: VoucherTemplateSettings(
            loginUrl: 'https://wifi.example.test/login',
            showPassword: true,
            showProfile: true,
            showValidity: true,
            showTimeLimit: true,
            showDataLimit: true,
            showPrice: true,
            showLoginUrl: true,
            showComment: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Hotspot'), findsOneWidget);
    expect(find.text('CODE VOUCHER'), findsOneWidget);
  });

  for (final layout in [
    VoucherPrintLayout.mikhmonCode,
    VoucherPrintLayout.mikhmonCredentials,
  ]) {
    testWidgets('${layout.name} reste lisible avec un pied dynamique', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: VoucherPrintScreen(
            vouchers: const [
              {
                'username': 'iu56b',
                'password': '482759',
                'validity': '1d',
                'limit-uptime': '2h',
                'selling-price': '100',
              },
            ],
            layout: layout,
            templateSettings: const VoucherTemplateSettings(
              hotspotName: 'AES Tech wifizone',
              footerText: 'Par AESOLTEC AFRIQUE',
              currency: 'CFA',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AES Tech wifizone'), findsOneWidget);
      expect(find.text('Par AESOLTEC AFRIQUE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
