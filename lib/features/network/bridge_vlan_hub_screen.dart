import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class BridgeVlanHubScreen extends StatelessWidget {
  final RouterOsService service;
  const BridgeVlanHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bridge & VLAN avancés')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Configurez d’abord les ports et le Bridge VLAN Table, puis '
              'vérifiez le management avant d’activer VLAN Filtering.',
            ),
          ),
        ),
        _button(
          context,
          'Bridges & VLAN Filtering sécurisé',
          AppRoutes.hubBridgeManagement,
        ),
        _button(context, 'Bridge Ports', AppRoutes.bridgePorts),
        _button(context, 'Bridge VLAN Table', AppRoutes.bridgeVlanTable),
        _button(context, 'Bridge Hosts / FDB', AppRoutes.bridgeHosts),
        _button(context, 'Interface Lists', AppRoutes.interfaceLists),
        _button(context, 'Audit sécurité VLAN', AppRoutes.bridgeVlanSafety),
        _button(
          context,
          'Compatibilité RouterOS',
          AppRoutes.bridgeVlanCapability,
        ),
      ],
    ),
  );

  Widget _button(BuildContext context, String title, String routeName) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => AppRouter.pushNamed(context, routeName),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(title),
            ),
          ),
        ),
      );
}
