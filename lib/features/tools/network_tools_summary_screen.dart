import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class NetworkToolsSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const NetworkToolsSummaryScreen({super.key, required this.service});

  @override
  State<NetworkToolsSummaryScreen> createState() =>
      _NetworkToolsSummaryScreenState();
}

class _NetworkToolsSummaryScreenState extends State<NetworkToolsSummaryScreen> {
  bool loading = true;
  Map<String, String> mode = {};
  Map<String, String> server = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      mode = await widget.service.deviceMode();
    } catch (_) {
      mode = {};
    }
    try {
      server = await widget.service.bandwidthServer();
    } catch (_) {
      server = {};
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé outils réseau'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _card(
                'Ping',
                'Disponible avec la policy test',
                Icons.network_ping,
              ),
              _card(
                'Traceroute',
                'Disponible avec la policy test',
                Icons.alt_route,
              ),
              _card(
                'Bandwidth Test',
                mode['bandwidth-test'] ?? 'Dépend du Device Mode',
                Icons.speed,
              ),
              _card(
                'Sniffer',
                mode['sniffer'] ?? 'Dépend du Device Mode',
                Icons.manage_search,
              ),
              _card(
                'Bandwidth Server',
                server['enabled'] ?? 'Inconnu',
                Icons.swap_horiz,
              ),
            ],
          ),
  );

  Widget _card(String title, String value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    ),
  );
}
