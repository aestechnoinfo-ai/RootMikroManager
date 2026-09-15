import 'bridge_vlan_hub_screen.dart';
// RootMikroManager VPN advanced entry: AppRoutes.hubVpnAdvancedHub
import 'vpn_advanced_hub_screen.dart';
import 'bridge_vlan_table_screen.dart';
import 'interface_lists_screen.dart';
import 'bridge_hosts_screen.dart';
import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import '../monitoring/interface_monitor_screen.dart';
import 'bridge_management_screen.dart';
import 'interfaces_management_screen.dart';
import 'ip_addresses_screen.dart';
import 'vlan_screen.dart';
import 'routing_ip_hub_screen.dart';

class InterfacesHubScreen extends StatelessWidget {
  final RouterOsService service;
  const InterfacesHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Interfaces')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Toutes les interfaces',
          'Inventaire, état, MTU, MAC et commentaires',
          Icons.settings_input_component_outlined,
          AppRoutes.hubInterfacesManagement,
        ),
        _button(
          context,
          'Monitoring RX/TX',
          'Débit temps réel avec streaming et polling',
          Icons.monitor_heart_outlined,
          AppRoutes.hubInterfaceMonitor,
        ),
        _button(
          context,
          'VLAN',
          'Interfaces VLAN 802.1Q',
          Icons.layers_outlined,
          AppRoutes.hubVlan,
        ),
        _button(
          context,
          'Bridges & ports',
          'Bridges, ports et PVID',
          Icons.device_hub_outlined,
          AppRoutes.hubBridgeManagement,
        ),
        _button(
          context,
          'Bridge & VLAN avancés',
          'Bridge VLAN Table, Interface Lists, FDB et audit de sécurité',
          Icons.account_tree_outlined,
          AppRoutes.hubBridgeVlanHub,
        ),
        _button(
          context,
          'Routage & IP',
          'Routes IPv4, ARP, adresses et neighbors',
          Icons.alt_route,
          AppRoutes.hubRoutingIpHub,
        ),
        _button(
          context,
          'Bridge Hosts / FDB',
          'MAC apprises, interfaces et VLAN',
          Icons.device_hub_outlined,
          AppRoutes.hubBridgeHosts,
        ),
        _button(
          context,
          'Interface Lists',
          'Listes, include/exclude et membres statiques',
          Icons.list_alt_outlined,
          AppRoutes.hubInterfaceLists,
        ),
        _button(
          context,
          'Adresses IP',
          'Adresses IPv4 liées aux interfaces',
          Icons.language_outlined,
          AppRoutes.hubIpAddresses,
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
