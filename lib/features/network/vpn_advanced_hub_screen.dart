import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'wireguard_interfaces_screen.dart';
import 'wireguard_peers_screen.dart';
import 'zerotier_interfaces_screen.dart';
import 'zerotier_peers_screen.dart';
import 'back_to_home_status_screen.dart';
import 'back_to_home_users_screen.dart';
import 'vpn_capability_status_screen.dart';
import 'vpn_neighbor_candidates_screen.dart';
import 'vpn_integration_summary_screen.dart';

class VpnAdvancedHubScreen extends StatelessWidget {
  final RouterOsService service;
  const VpnAdvancedHubScreen({super.key, required this.service});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('VPN avancé')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'WireGuard, ZeroTier, Back To Home et découverte des routeurs accessibles via VPN. Les secrets privés ne sont jamais affichés dans ce hub.',
            ),
          ),
        ),
        b(
          c,
          'Résumé VPN & Neighboring',
          Icons.dashboard_outlined,
          AppRoutes.hubVpnIntegrationSummary,
        ),
        b(
          c,
          'WireGuard interfaces',
          Icons.vpn_key_outlined,
          AppRoutes.hubWireGuardInterfaces,
        ),
        b(
          c,
          'WireGuard peers',
          Icons.people_outline,
          AppRoutes.hubWireGuardPeers,
        ),
        b(
          c,
          'ZeroTier interfaces',
          Icons.hub_outlined,
          AppRoutes.hubZeroTierInterfaces,
        ),
        b(
          c,
          'ZeroTier peers',
          Icons.device_hub_outlined,
          AppRoutes.hubZeroTierPeers,
        ),
        b(
          c,
          'Back To Home • statut',
          Icons.home_outlined,
          AppRoutes.hubBackToHomeStatus,
        ),
        b(
          c,
          'Back To Home • utilisateurs',
          Icons.manage_accounts_outlined,
          AppRoutes.hubBackToHomeUsers,
        ),
        b(
          c,
          'Neighboring via VPN',
          Icons.travel_explore_outlined,
          AppRoutes.hubVpnNeighborCandidates,
        ),
        b(
          c,
          'Compatibilité',
          Icons.fact_check_outlined,
          AppRoutes.hubVpnCapabilityStatus,
        ),
      ],
    ),
  );
  Widget b(BuildContext c, String t, IconData i, String routeName) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton.tonalIcon(
      onPressed: () => AppRouter.pushNamed(c, routeName),
      icon: Icon(i),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Align(alignment: Alignment.centerLeft, child: Text(t)),
      ),
    ),
  );
}
