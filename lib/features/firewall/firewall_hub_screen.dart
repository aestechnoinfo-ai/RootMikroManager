import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'firewall_address_list_screen.dart';
import 'firewall_management_screen.dart';

class FirewallHubScreen extends StatelessWidget {
  final RouterOsService service;
  const FirewallHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Firewall')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Filter Rules',
          Icons.filter_alt_outlined,
          AppRoutes.hubFirewallManagementFilter,
        ),
        _button(
          context,
          'NAT',
          Icons.swap_horiz,
          AppRoutes.hubFirewallManagementNat,
        ),
        _button(
          context,
          'Mangle',
          Icons.alt_route,
          AppRoutes.hubFirewallManagementMangle,
        ),
        _button(
          context,
          'Address Lists',
          Icons.list_alt,
          AppRoutes.hubFirewallAddressList,
        ),
      ],
    ),
  );

  Widget _button(
    BuildContext context,
    String title,
    IconData icon,
    String routeName,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton.tonalIcon(
      onPressed: () => AppRouter.pushNamed(context, routeName),
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Align(alignment: Alignment.centerLeft, child: Text(title)),
      ),
    ),
  );
}
