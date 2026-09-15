import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemOverviewScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemOverviewScreen({super.key, required this.service});

  @override
  State<SystemOverviewScreen> createState() => _SystemOverviewScreenState();
}

class _SystemOverviewScreenState extends State<SystemOverviewScreen> {
  bool loading = true;
  String? error;
  Map<String, String> identity = {};
  Map<String, String> resource = {};
  Map<String, String> clock = {};
  Map<String, String> board = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final values = await Future.wait([
        widget.service.identity(),
        widget.service.resource(),
        widget.service.systemClock(),
        widget.service.routerboard(),
      ]);
      identity = values[0];
      resource = values[1];
      clock = values[2];
      board = values[3];
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> confirm(String action) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              action == 'reboot'
                  ? 'Redémarrer le routeur ?'
                  : 'Éteindre le routeur ?',
            ),
            content: const Text(
              'Cette action affecte immédiatement le routeur connecté.',
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
        ) ??
        false;
    if (!ok) return;
    if (action == 'reboot') {
      await widget.service.reboot();
    } else {
      await widget.service.shutdown();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Vue générale système'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _section('Routeur', {
                  'Identity': identity['name'],
                  'Board': resource['board-name'],
                  'Modèle': board['model'],
                  'N° série': board['serial-number'],
                  'RouterOS': resource['version'],
                  'Firmware': board['current-firmware'],
                  'Architecture': resource['architecture-name'],
                  'Plateforme': resource['platform'],
                }),
                _section('Temps système', {
                  'Date': clock['date'],
                  'Heure': clock['time'],
                  'Fuseau': clock['time-zone-name'],
                  'GMT offset': clock['gmt-offset'],
                  'Uptime': resource['uptime'],
                }),
                _section('CPU / mémoire', {
                  'CPU': resource['cpu'],
                  'CPU count': resource['cpu-count'],
                  'CPU frequency': resource['cpu-frequency'],
                  'CPU load': resource['cpu-load'],
                  'RAM libre': resource['free-memory'],
                  'RAM totale': resource['total-memory'],
                }),
                _section('Stockage', {
                  'Libre': resource['free-hdd-space'],
                  'Total': resource['total-hdd-space'],
                  'Write sectors reboot': resource['write-sect-since-reboot'],
                  'Write sectors total': resource['write-sect-total'],
                }),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => confirm('reboot'),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Redémarrer'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => confirm('shutdown'),
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text('Éteindre'),
                    ),
                  ],
                ),
              ],
            ),
          ),
  );

  Widget _section(String title, Map<String, String?> values) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: values.entries
                .where((e) => (e.value ?? '').isNotEmpty)
                .map(
                  (e) => SizedBox(
                    width: 210,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          e.value ?? '—',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );
}
