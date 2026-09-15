import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'advanced_ping_screen.dart';
import 'bandwidth_test_screen.dart';
import 'device_mode_tools_screen.dart';
import 'network_tools_summary_screen.dart';
import 'sniffer_screen.dart';
import 'torch_screen.dart';
import 'traceroute_advanced_screen.dart';
import '../vpn/vpn_hub_screen.dart';

class NetworkToolsHubScreen extends StatelessWidget {
  final RouterOsService service;
  const NetworkToolsHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Outils réseau')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _b(
          context,
          'Résumé',
          'Disponibilité des outils et Device Mode',
          Icons.dashboard_outlined,
          AppRoutes.hubNetworkToolsSummary,
        ),
        _b(
          context,
          'VPN',
          'WireGuard, ZeroTier et Back to Home',
          Icons.vpn_lock_outlined,
          AppRoutes.hubVpnHub,
        ),
        _b(
          context,
          'Ping avancé',
          'RTT, TTL, perte, source et routing table',
          Icons.network_ping,
          AppRoutes.hubAdvancedPing,
        ),
        _b(
          context,
          'Traceroute',
          'Chemin et latence jusqu’à une destination',
          Icons.alt_route,
          AppRoutes.hubTracerouteAdvanced,
        ),
        _b(
          context,
          'Torch',
          'Analyse du trafic d’une interface',
          Icons.local_fire_department_outlined,
          AppRoutes.hubTorch,
        ),
        _b(
          context,
          'Bandwidth Test',
          'Test TCP/UDP limité pour éviter la saturation',
          Icons.speed,
          AppRoutes.hubBandwidthTest,
        ),
        _b(
          context,
          'Packet Sniffer',
          'Capture vers un fichier du routeur',
          Icons.manage_search,
          AppRoutes.hubSniffer,
        ),
        _b(
          context,
          'Device Mode',
          'Vérifier les restrictions RouterOS',
          Icons.admin_panel_settings_outlined,
          AppRoutes.hubDeviceModeTools,
        ),
      ],
    ),
  );

  Widget _b(BuildContext c, String t, String s, IconData i, String routeName) =>
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
