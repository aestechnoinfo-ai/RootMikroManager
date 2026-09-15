import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class DnsSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const DnsSummaryScreen({super.key, required this.service});

  @override
  State<DnsSummaryScreen> createState() => _DnsSummaryScreenState();
}

class _DnsSummaryScreenState extends State<DnsSummaryScreen> {
  bool loading = true;
  Map<String, String> settings = {};
  int staticEntries = 0;
  int cacheEntries = 0;
  int adlists = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final config = await widget.service.dnsSettings();
    final statics = await widget.service.dnsStatic();
    final cache = await widget.service.dnsCacheAll();
    var lists = <Map<String, String>>[];
    try {
      lists = await widget.service.dnsAdlists();
    } catch (_) {}
    settings = config;
    staticEntries = statics.length;
    cacheEntries = cache.length;
    adlists = lists.length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé DNS'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _card(
                'Remote Requests',
                (settings['allow-remote-requests'] ?? 'no') == 'yes'
                    ? 'Activé'
                    : 'Désactivé',
                Icons.lan_outlined,
              ),
              _card(
                'Serveurs DNS',
                settings['servers'] ?? '—',
                Icons.dns_outlined,
              ),
              _card(
                'DoH',
                (settings['use-doh-server'] ?? '').isEmpty
                    ? 'Désactivé'
                    : settings['use-doh-server']!,
                Icons.https_outlined,
              ),
              _card('DNS statiques', '$staticEntries', Icons.list_alt),
              _card('Entrées cache', '$cacheEntries', Icons.cached),
              _card('Adlists', '$adlists', Icons.block_outlined),
            ],
          ),
  );

  Widget _card(String label, String value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    ),
  );
}
