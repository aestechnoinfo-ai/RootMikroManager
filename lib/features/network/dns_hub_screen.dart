import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class DnsHubScreen extends StatelessWidget {
  final RouterOsService service;
  const DnsHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('DNS')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Résumé DNS',
          'Serveurs, cache, DoH et entrées',
          Icons.dashboard_outlined,
          AppRoutes.dnsSummary,
        ),
        _button(
          context,
          'Configuration DNS',
          'Serveurs, cache, DoH et remote requests',
          Icons.settings_outlined,
          AppRoutes.dnsSettings,
        ),
        _button(
          context,
          'DNS statique',
          'A, AAAA, CNAME, FWD et règles statiques',
          Icons.list_alt,
          AppRoutes.dnsStaticList,
        ),
        _button(
          context,
          'Cache DNS',
          'Inspecter et vider le cache',
          Icons.cached,
          AppRoutes.dnsCache,
        ),
        _button(
          context,
          'DNS Adlist',
          'Listes de domaines et blocage DNS',
          Icons.block_outlined,
          AppRoutes.dnsAdlist,
        ),
        _button(
          context,
          'Diagnostic DNS',
          'Résolution effectuée depuis RouterOS',
          Icons.troubleshoot,
          AppRoutes.dnsDiagnostics,
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
