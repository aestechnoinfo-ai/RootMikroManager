import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'firewall_address_list_screen.dart';
import 'firewall_rules_screen.dart';
import 'firewall_stats_screen.dart';
import 'mangle_tools_screen.dart';

class FirewallAdvancedHubScreen extends StatelessWidget {
  final RouterOsService service;
  const FirewallAdvancedHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Firewall avancé')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Filter Rules',
          'Filtrage input / forward / output',
          Icons.filter_alt_outlined,
          AppRoutes.hubFirewallRulesFilter,
        ),
        _button(
          context,
          'NAT',
          'Masquerade, src-nat, dst-nat et redirect',
          Icons.swap_horiz,
          AppRoutes.hubFirewallRulesNat,
        ),
        _button(
          context,
          'Mangle',
          'Packet, connection et routing marks',
          Icons.alt_route,
          AppRoutes.hubMangleTools,
        ),
        _button(
          context,
          'RAW',
          'Filtrage avant connection tracking / notrack',
          Icons.flash_on_outlined,
          AppRoutes.hubFirewallRulesRaw,
        ),
        _button(
          context,
          'Address Lists',
          'Listes statiques et dynamiques',
          Icons.list_alt,
          AppRoutes.hubFirewallAddressList,
        ),
        _button(
          context,
          'Statistiques',
          'Résumé des règles et états',
          Icons.bar_chart_outlined,
          AppRoutes.hubFirewallStats,
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
