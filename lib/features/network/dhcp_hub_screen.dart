import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class DhcpHubScreen extends StatelessWidget {
  final RouterOsService service;
  const DhcpHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('DHCP')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Résumé DHCP',
          'Serveurs, réseaux, pools et baux',
          Icons.dashboard_outlined,
          AppRoutes.dhcpSummary,
        ),
        _button(
          context,
          'Serveurs DHCP',
          'Interface, pool, lease-time et état',
          Icons.dns_outlined,
          AppRoutes.dhcpServersList,
        ),
        _button(
          context,
          'Réseaux DHCP',
          'Gateway, DNS, domaine, NTP et WINS',
          Icons.account_tree_outlined,
          AppRoutes.dhcpNetworksList,
        ),
        _button(
          context,
          'Baux DHCP',
          'Statiques, dynamiques et réservations',
          Icons.devices_outlined,
          AppRoutes.dhcpLeasesList,
        ),
        _button(
          context,
          'IP Pools',
          'Plages d’adresses utilisées par DHCP',
          Icons.hub_outlined,
          AppRoutes.hotspotIpPools,
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
