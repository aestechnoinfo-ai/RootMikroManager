import 'package:flutter/material.dart';

import '../../core/routeros/router_session.dart';
import 'router_diagnostics_service.dart';

class RouterApiDiagnosticsScreen extends StatefulWidget {
  const RouterApiDiagnosticsScreen({super.key});

  @override
  State<RouterApiDiagnosticsScreen> createState() =>
      _RouterApiDiagnosticsScreenState();
}

class _RouterApiDiagnosticsScreenState
    extends State<RouterApiDiagnosticsScreen> {
  bool busy = false;
  List<DiagnosticCheck> checks = [];

  Future<void> run() async {
    setState(() {
      busy = true;
      checks = [];
    });

    try {
      final router = RouterSession.instance.activeRouter;
      final service = RouterDiagnosticsService(RouterSession.instance.service);
      checks = await service.run(host: router?.host, port: router?.port);
    } catch (e) {
      checks = [DiagnosticCheck(name: 'Diagnostic', ok: false, detail: '$e')];
    }

    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnostic RouterOS')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Le diagnostic teste la joignabilité TCP du port configuré, '
              'la session RouterOS, les ressources, l’horloge et l’accès '
              'aux fichiers. Aucun changement de configuration n’est effectué.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : run,
          icon: const Icon(Icons.health_and_safety_outlined),
          label: Text(busy ? 'Diagnostic…' : 'Lancer le diagnostic'),
        ),
        if (busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 12),
        for (final check in checks)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (check.ok ? Colors.green : Colors.red)
                    .withValues(alpha: 0.12),
                child: Icon(
                  check.ok ? Icons.check : Icons.close,
                  color: check.ok ? Colors.green : Colors.red,
                ),
              ),
              title: Text(check.name),
              subtitle: Text(check.detail),
            ),
          ),
      ],
    ),
  );
}
