import 'package:flutter/material.dart';
import '../routers/routers_screen.dart';
import '../hotspot/hotspot_management_screen.dart';
import '../vouchers/voucher_generator_screen.dart';
import '../ppp/ppp_management_screen.dart';
import '../management/crud_router_screen.dart';
import '../network/network_screens.dart';
import '../firewall/firewall_management_screen.dart';
import '../monitoring/interface_monitor_screen.dart';
import '../tools/network_tools_screen.dart';
import '../system/system_screens.dart';
import '../system/router_system_screen.dart';
import '../backup/router_backup_screen.dart';
import '../reports/reports_screen.dart';
import '../../core/routeros/router_session.dart';

class ModuleScreen extends StatelessWidget {
  final String title;
  const ModuleScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final s = RouterSession.instance.service;
    if (title == 'Routeurs') return const RoutersScreen();
    if (!RouterSession.instance.connected) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucun routeur connecté.\n\nOuvrez Routeurs, sélectionnez un MikroTik puis appuyez sur « Connecter ».',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (title == 'Hotspot') return HotspotManagementScreen(service: s);
    if (title == 'Vouchers') {
      return VoucherGeneratorScreen(
        service: s,
        routerId: RouterSession.instance.activeRouter?.id,
      );
    }
    if (title == 'PPPoE') return PppManagementScreen(service: s);
    if (title == 'DHCP')
      return CrudRouterScreen(
        title: 'DHCP Leases',
        path: '/ip/dhcp-server/lease',
        loader: s.dhcpLeases,
      );
    if (title == 'DNS')
      return CrudRouterScreen(
        title: 'DNS statique',
        path: '/ip/dns/static',
        loader: s.dnsStatic,
      );
    if (title == 'Interfaces') return const InterfacesScreen();
    if (title == 'Firewall')
      return const FirewallManagementScreen(
        title: 'Firewall',
        path: '/ip/firewall/filter',
      );
    if (title == 'Queues')
      return CrudRouterScreen(
        title: 'Simple Queues',
        path: '/queue/simple',
        loader: s.simpleQueues,
      );
    if (title == 'Traffic') return InterfaceMonitorScreen(service: s);
    if (title == 'Wireless') return const WirelessScreen();
    if (title == 'Tools') return NetworkToolsScreen(service: s);
    if (title == 'Scripts') return const ScriptsScreen();
    if (title == 'Scheduler') return const SchedulerScreen();
    if (title == 'Logs') return const LogsScreen();
    if (title == 'Backup') return RouterBackupScreen(service: s);
    if (title == 'Reports') return ReportsScreen(service: s);
    if (title == 'Settings') return RouterSystemScreen(service: s);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title en préparation.')),
    );
  }
}
