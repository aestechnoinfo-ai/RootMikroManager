import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class DiscoveryScreen extends StatelessWidget {
  final RouterOsService service;
  const DiscoveryScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Voisinage & découverte')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'RootMikroManager combine plusieurs méthodes : '
              'Neighbors Layer 2 vus par le routeur, scan IP local/VPN '
              'et découverte RoMON depuis un MikroTik déjà joignable.',
            ),
          ),
        ),
        const SizedBox(height: 8),
        _button(
          context,
          'Neighbors',
          'MNDP / CDP / LLDP vus par le routeur connecté',
          Icons.device_hub_outlined,
          AppRoutes.discoveryNeighbors,
        ),
        _button(
          context,
          'VPN Discovery',
          'WireGuard, BackToHome, ZeroTier et CIDR manuels',
          Icons.vpn_lock_outlined,
          AppRoutes.discoveryVpn,
        ),
        _button(
          context,
          'RoMON',
          'Découverte RoMON via le routeur connecté',
          Icons.hub_outlined,
          AppRoutes.discoveryRomon,
        ),
        _button(
          context,
          'Scan IP',
          'Scan direct des ports RouterOS / Winbox',
          Icons.radar,
          AppRoutes.discoveryIpScan,
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
