import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'queue_monitor_screen.dart';
import 'queue_stats_screen.dart';
import 'queue_tree_screen.dart';
import 'queue_type_screen.dart';
import 'simple_queue_screen.dart';

class QueuesHubScreen extends StatelessWidget {
  final RouterOsService service;
  const QueuesHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Queues')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Simple Queues',
          'Cibles, limites, burst, priorité et parent',
          Icons.speed,
          AppRoutes.hubSimpleQueue,
        ),
        _button(
          context,
          'Queue Tree',
          'Arbre de queues et packet marks',
          Icons.account_tree_outlined,
          AppRoutes.hubQueueTree,
        ),
        _button(
          context,
          'Queue Types',
          'PCQ, FIFO, SFQ, CAKE, CoDel et autres',
          Icons.tune,
          AppRoutes.hubQueueType,
        ),
        _button(
          context,
          'Monitoring',
          'Débits, octets, paquets et files en temps réel',
          Icons.monitor_heart_outlined,
          AppRoutes.hubQueueMonitor,
        ),
        _button(
          context,
          'Statistiques',
          'Résumé Simple, Tree, Types et désactivées',
          Icons.bar_chart_outlined,
          AppRoutes.hubQueueStats,
        ),
      ],
    ),
  );

  Widget _button(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String routeName,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton.tonalIcon(
      onPressed: () => AppRouter.pushNamed(context, routeName),
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}
