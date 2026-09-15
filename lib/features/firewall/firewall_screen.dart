import 'package:flutter/material.dart';
import '../network/network_screens.dart';
import '../../core/routeros/router_session.dart';

class FirewallScreen extends StatelessWidget {
  const FirewallScreen({super.key});
  @override
  Widget build(BuildContext c) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Firewall'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Filter'),
            Tab(text: 'NAT'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          RouterListScreen(
            title: 'Règles Filter',
            loader: () => RouterSession.instance.service.firewallFilter(),
          ),
          RouterListScreen(
            title: 'Règles NAT',
            loader: () => RouterSession.instance.service.firewallNat(),
          ),
        ],
      ),
    ),
  );
}
