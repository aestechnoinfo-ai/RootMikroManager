import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'automation_summary_screen.dart';
import 'scheduler_linkage_screen.dart';
import 'scheduler_management_screen.dart';
import 'script_permissions_screen.dart';
import 'scripts_management_screen.dart';
import 'script_jobs_screen.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';

class AutomationHubScreen extends StatelessWidget {
  final RouterOsService service;
  const AutomationHubScreen({super.key, required this.service});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Scripts & Scheduler')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        b(
          c,
          'Résumé',
          'Scripts, schedulers actifs et récurrence',
          Icons.dashboard_outlined,
          AppRoutes.hubAutomationSummary,
        ),
        b(
          c,
          'Scripts RouterOS',
          'Créer, modifier, exécuter et inspecter',
          Icons.code,
          AppRoutes.hubScriptsManagement,
        ),
        b(
          c,
          'Jobs actifs',
          'Voir et interrompre les scripts en cours',
          Icons.play_circle_outline,
          AppRoutes.hubScriptJobs,
        ),
        b(
          c,
          'Scheduler',
          'Planification, activation et prochaine exécution',
          Icons.event_repeat_outlined,
          AppRoutes.hubSchedulerManagement,
        ),
        b(
          c,
          'Liaisons',
          'Scripts appelés et écarts de policies',
          Icons.account_tree_outlined,
          AppRoutes.hubSchedulerLinkage,
        ),
        b(
          c,
          'Permissions',
          'Comprendre les contextes de permissions RouterOS',
          Icons.verified_user_outlined,
          AppRoutes.hubScriptPermissions,
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
