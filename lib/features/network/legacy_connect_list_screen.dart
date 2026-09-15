import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class LegacyConnectListScreen extends StatefulWidget {
  final RouterOsService service;
  const LegacyConnectListScreen({super.key, required this.service});
  @override
  State<LegacyConnectListScreen> createState() => _S();
}

class _S extends State<LegacyConnectListScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.legacyWirelessConnectList();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Wireless legacy • Connect List'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'La Connect List est ordonnée : seule la première règle correspondante est appliquée.',
                  ),
                ),
              ),
              for (final r in rows)
                Card(
                  child: ListTile(
                    leading: Icon(
                      r['connect'] == 'no' ? Icons.link_off : Icons.link,
                    ),
                    title: Text(
                      (r['ssid'] ?? '').isNotEmpty
                          ? r['ssid']!
                          : r['mac-address'] ?? 'Règle',
                    ),
                    subtitle: Text(
                      [
                        'Connect ${r['connect'] ?? 'yes'}',
                        if ((r['interface'] ?? '').isNotEmpty) r['interface']!,
                        if ((r['signal-range'] ?? '').isNotEmpty)
                          r['signal-range']!,
                      ].join(' • '),
                    ),
                  ),
                ),
            ],
          ),
  );
}
