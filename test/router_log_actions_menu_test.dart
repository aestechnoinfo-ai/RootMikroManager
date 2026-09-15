import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/core/routeros/routeros_service.dart';
import 'package:root_mikro_manager/features/logs/router_log_actions_menu.dart';

class _LogRouter extends RouterOsService {
  int clears = 0;
  int? lineLimit;

  @override
  Future<int> clearAllMemoryLogs() async {
    clears++;
    return 1;
  }

  @override
  Future<void> limitDefaultMemoryLogsTo200() async => lineLimit = 200;

  @override
  Future<void> disableDefaultMemoryLogLimit() async => lineLimit = 1000;
}

void main() {
  Future<void> selectAndConfirm(WidgetTester tester, String actionLabel) async {
    await tester.tap(find.byTooltip('Actions sur les logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(actionLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'les commandes de limitation et de restauration sont distinctes',
    (tester) async {
      final router = _LogRouter();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RouterLogActionsMenu(service: router)),
        ),
      );

      await selectAndConfirm(tester, 'Limiter à 200 lignes');
      expect(router.lineLimit, 200);

      await selectAndConfirm(tester, 'Retirer la limite de 200');
      expect(router.lineLimit, 1000);

      await selectAndConfirm(tester, 'Vider les logs mémoire');
      expect(router.clears, 1);
    },
  );
}
