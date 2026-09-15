import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'system_overview_screen.dart';
import 'system_health_screen.dart';
import 'system_packages_screen.dart';
import 'system_ntp_screen.dart';
import 'system_storage_screen.dart';
import 'system_screens.dart';
import 'system_security_hub_screen.dart';
import 'automation_hub_screen.dart';
import 'logging_hub_screen.dart';

class SystemHubScreen extends StatelessWidget {
  final RouterOsService service;
  const SystemHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Système')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Administration & sécurité',
          Icons.security_outlined,
          AppRoutes.hubSystemSecurityHub,
        ),
        _button(
          context,
          'Vue générale',
          Icons.dashboard_outlined,
          AppRoutes.hubSystemOverview,
        ),
        _button(
          context,
          'Santé matériel',
          Icons.monitor_heart_outlined,
          AppRoutes.hubSystemHealth,
        ),
        _button(
          context,
          'Stockage / fichiers',
          Icons.storage_outlined,
          AppRoutes.hubSystemStorage,
        ),
        _button(
          context,
          'Packages / mises à jour',
          Icons.system_update_alt_outlined,
          AppRoutes.hubSystemPackages,
        ),
        _button(
          context,
          'NTP / heure réseau',
          Icons.schedule_outlined,
          AppRoutes.hubSystemNtp,
        ),
        _button(
          context,
          'Scripts & Scheduler',
          Icons.integration_instructions_outlined,
          AppRoutes.hubAutomationHub,
        ),
        _button(
          context,
          'Logs & journalisation',
          Icons.article_outlined,
          AppRoutes.hubLoggingHub,
        ),
      ],
    ),
  );

  Widget _button(
    BuildContext context,
    String label,
    IconData icon,
    String routeName,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton.tonalIcon(
      onPressed: () => AppRouter.pushNamed(context, routeName),
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    ),
  );
}
