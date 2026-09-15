import 'package:flutter/material.dart';

import '../../core/navigation/routes.dart';

class AppDrawer extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const AppDrawer({super.key, required this.onSelect});

  static const mikhmonItems =
      <({String label, String routeName, IconData icon})>[
        (
          label: 'Dashboard',
          routeName: AppRoutes.dashboard,
          icon: Icons.dashboard_outlined,
        ),
        (
          label: 'Hotspot',
          routeName: AppRoutes.hotspot,
          icon: Icons.wifi_outlined,
        ),
        (
          label: 'Gestion PPP / PPPoE',
          routeName: AppRoutes.hubPppManagement,
          icon: Icons.manage_accounts_outlined,
        ),
        (
          label: 'Vouchers',
          routeName: AppRoutes.vouchers,
          icon: Icons.confirmation_number_outlined,
        ),
        (
          label: 'Rapports',
          routeName: AppRoutes.reports,
          icon: Icons.analytics_outlined,
        ),
      ];

  static const winboxItems =
      <({String label, String routeName, IconData icon})>[
        (
          label: 'Hotspot (WinBox)',
          routeName: AppRoutes.hotspotWinbox,
          icon: Icons.wifi_tethering,
        ),
        (
          label: 'PPPoE',
          routeName: AppRoutes.ppp,
          icon: Icons.vpn_key_outlined,
        ),
        (label: 'DHCP', routeName: AppRoutes.dhcp, icon: Icons.lan_outlined),
        (label: 'DNS', routeName: AppRoutes.dns, icon: Icons.dns_outlined),
        (
          label: 'Interfaces',
          routeName: AppRoutes.interfaces,
          icon: Icons.settings_ethernet,
        ),
        (
          label: 'Firewall',
          routeName: AppRoutes.firewall,
          icon: Icons.security_outlined,
        ),
        (label: 'NAT', routeName: AppRoutes.nat, icon: Icons.swap_horiz),
        (
          label: 'Queues',
          routeName: AppRoutes.queues,
          icon: Icons.speed_outlined,
        ),
        (label: 'Trafic', routeName: AppRoutes.traffic, icon: Icons.show_chart),
        (label: 'Wireless', routeName: AppRoutes.wireless, icon: Icons.wifi),
        (
          label: 'Voisinage',
          routeName: AppRoutes.neighbors,
          icon: Icons.device_hub_outlined,
        ),
        (
          label: 'Scan réseau',
          routeName: AppRoutes.networkScan,
          icon: Icons.radar,
        ),
        (
          label: 'Outils',
          routeName: AppRoutes.tools,
          icon: Icons.build_outlined,
        ),
        (label: 'Scripts', routeName: AppRoutes.scripts, icon: Icons.code),
        (
          label: 'Scheduler',
          routeName: AppRoutes.scheduler,
          icon: Icons.schedule,
        ),
        (
          label: 'Logs',
          routeName: AppRoutes.logs,
          icon: Icons.article_outlined,
        ),
        (
          label: 'Backup',
          routeName: AppRoutes.backup,
          icon: Icons.backup_outlined,
        ),
        (
          label: 'Audit',
          routeName: AppRoutes.audit,
          icon: Icons.fact_check_outlined,
        ),
      ];

  static const appItems = <({String label, String routeName, IconData icon})>[
    (
      label: 'Routeurs',
      routeName: AppRoutes.routers,
      icon: Icons.router_outlined,
    ),
    (
      label: 'Réglages vouchers',
      routeName: AppRoutes.voucherTemplateEditor,
      icon: Icons.receipt_long_outlined,
    ),
    (
      label: 'Paramètres de l’app',
      routeName: AppRoutes.settings,
      icon: Icons.settings_outlined,
    ),
  ];

  Widget _section(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required List<({String label, String routeName, IconData icon})> items,
    bool initiallyExpanded = false,
  }) => Container(
    margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
    ),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      backgroundColor: backgroundColor,
      collapsedBackgroundColor: backgroundColor,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      children: [
        for (final item in items)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            leading: Icon(item.icon),
            title: Text(item.label),
            onTap: () {
              Navigator.pop(context);
              onSelect(item.routeName);
            },
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Image.asset(
                      'lib/assets/images/logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      semanticLabel: 'Logo RootMikroManager',
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'ROOT M. M',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _section(
              context,
              title: 'Hotspot / R.M.M',
              subtitle: 'Tickets, utilisateurs et ventes',
              icon: Icons.point_of_sale_outlined,
              backgroundColor: colors.primaryContainer.withValues(alpha: 0.55),
              items: mikhmonItems,
              initiallyExpanded: true,
            ),
            _section(
              context,
              title: 'Administration / RootBox',
              subtitle: 'Réseau et RouterOS',
              icon: Icons.router_outlined,
              backgroundColor: colors.secondaryContainer.withValues(
                alpha: 0.55,
              ),
              items: winboxItems,
            ),
            _section(
              context,
              title: 'Application',
              subtitle: 'Routeurs, vouchers et paramètres',
              icon: Icons.tune,
              backgroundColor: colors.tertiaryContainer.withValues(alpha: 0.55),
              items: appItems,
            ),
          ],
        ),
      ),
    );
  }
}
