import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotSettingsScreen extends StatelessWidget {
  final RouterOsService service;
  const HotspotSettingsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configuration Hotspot')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Résumé configuration',
          Icons.dashboard_outlined,
          AppRoutes.hotspotSetupSummary,
        ),
        _button(
          context,
          'Hotspot Servers',
          Icons.router_outlined,
          AppRoutes.hotspotServers,
        ),
        _button(
          context,
          'Server Profiles',
          Icons.settings_ethernet_outlined,
          AppRoutes.hotspotServerProfiles,
        ),
        _button(
          context,
          'IP Pools',
          Icons.hub_outlined,
          AppRoutes.hotspotIpPools,
        ),
        _button(
          context,
          'Sessions actives',
          Icons.wifi_tethering,
          AppRoutes.hotspotActive,
        ),
      ],
    ),
  );

  Widget _button(
    BuildContext context,
    String title,
    IconData icon,
    String routeName,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton.tonalIcon(
      onPressed: () => AppRouter.pushNamed(context, routeName),
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Align(alignment: Alignment.centerLeft, child: Text(title)),
      ),
    ),
  );
}
