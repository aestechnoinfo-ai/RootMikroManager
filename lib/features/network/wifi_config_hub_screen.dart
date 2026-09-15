import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'wifi_access_list_screen.dart';
import 'wifi_capsman_screen.dart';
import 'wifi_config_backend.dart';
import 'wifi_config_summary_screen.dart';
import 'wifi_profiles_screen.dart';
import 'wifi_acl_safety_screen.dart';
import 'wifi_provisioning_screen.dart';
import 'legacy_connect_list_screen.dart';

class WifiConfigHubScreen extends StatelessWidget {
  final RouterOsService service;
  const WifiConfigHubScreen({super.key, required this.service});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configuration WiFi avancée')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Deux backends distincts : /interface/wifi et Wireless legacy. Les règles et profils ne sont pas fusionnés.',
            ),
          ),
        ),
        b(
          context,
          'Résumé',
          'Inventaire des deux familles',
          Icons.dashboard_outlined,
          AppRoutes.hubWifiConfigSummary,
        ),
        b(
          context,
          'Access List • WiFi moderne',
          'Accept, reject, query-radius, signal et VLAN',
          Icons.security_outlined,
          AppRoutes.hubWifiAccessListModern,
        ),
        b(
          context,
          'Access List • Wireless legacy',
          'Authentication, forwarding et signal',
          Icons.admin_panel_settings_outlined,
          AppRoutes.hubWifiAccessListLegacy,
        ),
        b(
          context,
          'Connect List legacy',
          'Priorité des AP en mode station',
          Icons.link_outlined,
          AppRoutes.hubLegacyConnectList,
        ),
        b(
          context,
          'Profils WiFi moderne',
          'Configuration, channel, security et datapath',
          Icons.tune,
          AppRoutes.hubWifiProfiles,
        ),
        b(
          context,
          'WiFi CAPsMAN',
          'Remote CAP et provisioning',
          Icons.router_outlined,
          AppRoutes.hubWifiCapsman,
        ),
        b(
          context,
          'Provisioning WiFi',
          'CRUD des règles CAPsMAN',
          Icons.auto_awesome_motion_outlined,
          AppRoutes.hubWifiProvisioning,
        ),
        b(
          context,
          'Audit Access Lists',
          'Ordre, rejets généraux et VLAN',
          Icons.fact_check_outlined,
          AppRoutes.hubWifiAclSafety,
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
