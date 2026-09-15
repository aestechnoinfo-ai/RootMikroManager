import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RouterSystemScreen extends StatefulWidget {
  final RouterOsService service;
  const RouterSystemScreen({super.key, required this.service});

  @override
  State<RouterSystemScreen> createState() => _RouterSystemScreenState();
}

class _RouterSystemScreenState extends State<RouterSystemScreen> {
  Map<String, String>? identity;
  Map<String, String>? resource;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      identity = await widget.service.identity();
      resource = await widget.service.resource();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> confirmAction(String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          action == 'reboot'
              ? 'Redémarrer le routeur ?'
              : 'Éteindre le routeur ?',
        ),
        content: const Text(
          'Cette action affecte immédiatement le routeur MikroTik connecté.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (action == 'reboot') {
      await widget.service.reboot();
    } else {
      await widget.service.shutdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Système')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _Info('Identity', identity?['name'] ?? '—'),
                          _Info('Version', resource?['version'] ?? '—'),
                          _Info('Board', resource?['board-name'] ?? '—'),
                          _Info(
                            'Architecture',
                            resource?['architecture-name'] ?? '—',
                          ),
                          _Info('CPU', resource?['cpu'] ?? '—'),
                          _Info('CPU load', '${resource?['cpu-load'] ?? '—'}%'),
                          _Info('Free memory', resource?['free-memory'] ?? '—'),
                          _Info(
                            'Total memory',
                            resource?['total-memory'] ?? '—',
                          ),
                          _Info('Uptime', resource?['uptime'] ?? '—'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => confirmAction('reboot'),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Redémarrer'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => confirmAction('shutdown'),
                        icon: const Icon(Icons.power_settings_new),
                        label: const Text('Éteindre'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
