import 'package:flutter/material.dart';

import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';

/// Technical RouterOS Hotspot entry point, intentionally separated from the
/// RootMikroManager/Mikhmon-oriented commercial workflow.
class HotspotWinboxScreen extends StatelessWidget {
  const HotspotWinboxScreen({super.key});

  static const configurationItems = <_HotspotWinboxItem>[
    _HotspotWinboxItem(
      'Hotspot Setup',
      'État général et assistant de configuration',
      Icons.auto_fix_high_outlined,
      AppRoutes.hotspotSetupSummary,
    ),
    _HotspotWinboxItem(
      'Servers',
      '/ip/hotspot',
      Icons.router_outlined,
      AppRoutes.hotspotServers,
    ),
    _HotspotWinboxItem(
      'Server Profiles',
      '/ip/hotspot/profile',
      Icons.settings_ethernet_outlined,
      AppRoutes.hotspotServerProfiles,
    ),
    _HotspotWinboxItem(
      'IP Pools',
      '/ip/pool',
      Icons.hub_outlined,
      AppRoutes.hotspotIpPools,
    ),
  ];

  static const accessItems = <_HotspotWinboxItem>[
    _HotspotWinboxItem(
      'Users',
      '/ip/hotspot/user',
      Icons.people_outline,
      AppRoutes.hotspotWinboxUsers,
    ),
    _HotspotWinboxItem(
      'User Profiles',
      '/ip/hotspot/user/profile',
      Icons.badge_outlined,
      AppRoutes.hotspotWinboxProfiles,
    ),
    _HotspotWinboxItem(
      'Active · Hosts · Cookies · IP Bindings',
      'Sessions et contrôle d’accès en temps réel',
      Icons.monitor_heart_outlined,
      AppRoutes.hotspotWinboxRuntime,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hotspot — WinBox')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Administration RouterOS native'),
            subtitle: Text(
              'Ces menus correspondent aux objets IP > Hotspot de WinBox. '
              'La gestion commerciale reste dans Hotspot / R.M.M.',
            ),
          ),
        ),
        _section(context, 'Configuration', configurationItems),
        _section(context, 'Accès et sessions', accessItems),
      ],
    ),
  );

  Widget _section(
    BuildContext context,
    String title,
    List<_HotspotWinboxItem> items,
  ) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in items)
          Card(
            child: ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AppRouter.pushNamed(context, item.routeName),
            ),
          ),
      ],
    ),
  );
}

class _HotspotWinboxItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;

  const _HotspotWinboxItem(
    this.title,
    this.subtitle,
    this.icon,
    this.routeName,
  );
}
