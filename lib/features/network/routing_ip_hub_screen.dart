import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class RoutingIpHubScreen extends StatelessWidget {
  final RouterOsService service;
  const RoutingIpHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Routage & IP')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Résumé',
          'Routes, ARP et adresses',
          Icons.dashboard_outlined,
          AppRoutes.routingSummary,
        ),
        _button(
          context,
          'Routes IPv4',
          'Routes statiques/dynamiques et état détaillé',
          Icons.alt_route,
          AppRoutes.ipRoutesList,
        ),
        _button(
          context,
          'ARP',
          'Entrées dynamiques, statiques et published',
          Icons.link_outlined,
          AppRoutes.arpList,
        ),
        _button(
          context,
          'Adresses IP',
          'Adresses IPv4 des interfaces',
          Icons.language_outlined,
          AppRoutes.ipAddresses,
        ),
        _button(
          context,
          'IP Neighbors',
          'Voisins découverts par RouterOS',
          Icons.radar,
          AppRoutes.ipNeighbors,
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
