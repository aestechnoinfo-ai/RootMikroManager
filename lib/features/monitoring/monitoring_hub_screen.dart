import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';

import '../../core/routeros/router_session.dart';

class MonitoringHubScreen extends StatelessWidget {
  const MonitoringHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = RouterSession.instance.service;

    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FilledButton.tonalIcon(
            onPressed: () =>
                AppRouter.pushNamed(context, AppRoutes.monitorInterfaces),
            icon: const Icon(Icons.show_chart),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Traffic interfaces en temps réel'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () =>
                AppRouter.pushNamed(context, AppRoutes.monitorTorch),
            icon: const Icon(Icons.bolt_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Torch temps réel'),
              ),
            ),
          ),

          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () =>
                AppRouter.pushNamed(context, AppRoutes.monitorConnection),
            icon: const Icon(Icons.network_check),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Test connexion API (compatibilité RootMikroManager)',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
