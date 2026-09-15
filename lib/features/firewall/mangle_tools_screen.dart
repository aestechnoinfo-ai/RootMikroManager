import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'internet_sharing_service.dart';
import 'internet_sharing_status.dart';
import 'internet_sharing_summary_card.dart';

class MangleToolsScreen extends StatefulWidget {
  final RouterOsService service;
  const MangleToolsScreen({super.key, required this.service});

  @override
  State<MangleToolsScreen> createState() => _MangleToolsScreenState();
}

class _MangleToolsScreenState extends State<MangleToolsScreen> {
  InternetSharingStatus status = const InternetSharingStatus(
    protectedInterfaces: 0,
    enabledRules: 0,
    disabledRules: 0,
  );

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final rules = await InternetSharingService(widget.service).managedRules();
    if (mounted) {
      setState(() => status = InternetSharingStatus.fromRules(rules));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mangle')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        InternetSharingSummaryCard(status: status),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () =>
              AppRouter.pushNamed(context, AppRoutes.firewallMangleRules),
          icon: const Icon(Icons.alt_route),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Règles Mangle'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () async {
            await AppRouter.pushNamed(context, AppRoutes.internetSharing);
            await load();
          },
          icon: const Icon(Icons.block_outlined),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Désactiver / gérer le partage Internet'),
            ),
          ),
        ),
      ],
    ),
  );
}
