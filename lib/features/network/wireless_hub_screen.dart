import 'wifi_config_hub_screen.dart';
import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'wireless_inventory_screen.dart';
import 'wireless_registration_screen.dart';
import 'wireless_scan_screen.dart';
import 'wireless_security_screen.dart';
import 'wireless_summary_screen.dart';

class WirelessHubScreen extends StatelessWidget {
  final RouterOsService service;
  const WirelessHubScreen({super.key, required this.service});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wi‑Fi / Wireless')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _b(
          context,
          'Résumé',
          'Détection WiFi et Wireless, clients et profils',
          Icons.dashboard_outlined,
          AppRoutes.hubWirelessSummary,
        ),
        _b(
          context,
          'Interfaces radio',
          'Inventaire, état, SSID, bande et fréquence',
          Icons.wifi,
          AppRoutes.hubWirelessInventory,
        ),
        _b(
          context,
          'Clients connectés',
          'Registration table et déconnexion',
          Icons.devices_outlined,
          AppRoutes.hubWirelessRegistration,
        ),
        _b(
          context,
          'Sécurité',
          'Profils de sécurité sans afficher les secrets',
          Icons.security_outlined,
          AppRoutes.hubWirelessSecurity,
        ),
        _b(
          context,
          'Scan Wi‑Fi',
          'Scanner depuis une interface radio',
          Icons.radar,
          AppRoutes.hubWirelessScan,
        ),
        _b(
          context,
          'Configuration WiFi avancée',
          'ACL, profils, Connect List et CAPsMAN',
          Icons.settings_input_antenna,
          AppRoutes.hubWifiConfigHub,
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
