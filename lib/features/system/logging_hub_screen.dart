import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'logging_actions_screen.dart';
import 'logging_rules_screen.dart';
import 'logging_summary_screen.dart';
import 'logs_management_screen.dart';
import 'logging_buffers_screen.dart';
import 'logging_diagnostics_screen.dart';
import 'logging_export_screen.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';

class LoggingHubScreen extends StatelessWidget {
  final RouterOsService service;
  const LoggingHubScreen({super.key, required this.service});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Logs & journalisation')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        b(
          c,
          'Résumé',
          'Logs, erreurs, warnings, règles et actions',
          Icons.dashboard_outlined,
          AppRoutes.hubLoggingSummary,
        ),
        b(
          c,
          'Logs RouterOS',
          'Recherche, topic, sévérité, buffer et auto-refresh',
          Icons.article_outlined,
          AppRoutes.hubLogsManagement,
        ),
        b(
          c,
          'Buffers mémoire',
          'Afficher séparément les buffers target=memory',
          Icons.memory_outlined,
          AppRoutes.hubLoggingBuffers,
        ),
        b(
          c,
          'Règles de logging',
          'Topics, exclusions, regex et alertes de volume',
          Icons.rule_outlined,
          AppRoutes.hubLoggingRules,
        ),
        b(
          c,
          'Actions de logging',
          'Memory, disk, remote, email, echo, VRF et syslog',
          Icons.output_outlined,
          AppRoutes.hubLoggingActions,
        ),
        b(
          c,
          'Diagnostic',
          'Actions manquantes et combinaisons incompatibles',
          Icons.health_and_safety_outlined,
          AppRoutes.hubLoggingDiagnostics,
        ),
        b(
          c,
          'Export',
          'CSV ou texte copiable',
          Icons.download_outlined,
          AppRoutes.hubLoggingExport,
        ),
      ],
    ),
  );
  Widget b(BuildContext c, String t, String s, IconData i, String routeName) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FilledButton.tonalIcon(
          onPressed: () => AppRouter.pushNamed(c, routeName),
          icon: Icon(i),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t),
                  Text(s, style: Theme.of(c).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );
}
