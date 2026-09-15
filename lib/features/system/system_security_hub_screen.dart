import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'certificates_screen.dart';
import 'ip_services_screen.dart';
import 'system_clock_screen.dart';
import 'system_identity_screen.dart';
import 'system_security_summary_screen.dart';
import 'system_user_groups_screen.dart';
import 'system_users_screen.dart';

class SystemSecurityHubScreen extends StatelessWidget {
  final RouterOsService service;
  const SystemSecurityHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administration & sécurité')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Résumé sécurité',
          Icons.security_outlined,
          AppRoutes.hubSystemSecuritySummary,
        ),
        _button(
          context,
          'Identité du routeur',
          Icons.badge_outlined,
          AppRoutes.hubSystemIdentity,
        ),
        _button(
          context,
          'Horloge et fuseau',
          Icons.schedule_outlined,
          AppRoutes.hubSystemClock,
        ),
        _button(
          context,
          'Utilisateurs RouterOS',
          Icons.people_outline,
          AppRoutes.hubSystemUsers,
        ),
        _button(
          context,
          'Groupes utilisateurs',
          Icons.groups_outlined,
          AppRoutes.hubSystemUserGroups,
        ),
        _button(
          context,
          'Services IP',
          Icons.settings_ethernet_outlined,
          AppRoutes.hubIpServices,
        ),
        _button(
          context,
          'Certificats',
          Icons.verified_user_outlined,
          AppRoutes.hubCertificates,
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    ),
  );
}
