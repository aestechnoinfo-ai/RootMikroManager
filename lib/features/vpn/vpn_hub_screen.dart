import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class VpnHubScreen extends StatelessWidget {
  final RouterOsService service;
  const VpnHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('VPN')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Résumé VPN',
          'WireGuard, ZeroTier et Back to Home',
          Icons.dashboard_outlined,
          AppRoutes.vpnSummary,
        ),
        _button(
          context,
          'WireGuard',
          'Interfaces, peers et handshakes',
          Icons.vpn_key_outlined,
          AppRoutes.vpnWireGuardInterfaces,
        ),
        _button(
          context,
          'ZeroTier',
          'Réseaux virtuels et routes gérées',
          Icons.hub_outlined,
          AppRoutes.vpnZeroTier,
        ),
        _button(
          context,
          'Back to Home',
          'État Cloud VPN et utilisateurs',
          Icons.home_work_outlined,
          AppRoutes.vpnBackToHome,
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
