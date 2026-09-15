import 'routing_policy_safety_screen.dart';
import 'ipv6_nd_screen.dart';
import 'ipv6_routes_screen.dart';
import 'ipv6_addresses_screen.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'routing_tables_screen.dart';
import 'routing_rules_screen.dart';
import 'vrf_screen.dart';
import 'ipv6_inventory_screen.dart';
import 'routing_policy_summary_screen.dart';

class RoutingPolicyHubScreen extends StatelessWidget {
  final RouterOsService service;
  const RoutingPolicyHubScreen({super.key, required this.service});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Routage avancé & IPv6')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'RouterOS v7 sépare tables, règles et routes IPv4/IPv6.',
            ),
          ),
        ),
        b(c, 'Résumé', AppRoutes.hubRoutingPolicySummary),
        b(c, 'Tables de routage', AppRoutes.hubRoutingTables),
        b(c, 'Policy Routing Rules', AppRoutes.hubRoutingRules),
        b(c, 'VRF', AppRoutes.hubVrf),
        b(c, 'IPv6 • Inventaire', AppRoutes.hubIpv6Inventory),
        b(c, 'IPv6 • Adresses', AppRoutes.hubIpv6Addresses),
        b(c, 'IPv6 • Routes', AppRoutes.hubIpv6Routes),
        b(c, 'IPv6 • Neighbor Discovery', AppRoutes.hubIpv6Nd),
        b(c, 'Audit sécurité', AppRoutes.hubRoutingPolicySafety),
      ],
    ),
  );
  Widget b(BuildContext c, String t, String routeName) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: () => AppRouter.pushNamed(c, routeName),
        child: Padding(padding: const EdgeInsets.all(14), child: Text(t)),
      ),
    ),
  );
}
