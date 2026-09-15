import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class BridgeHostsScreen extends StatefulWidget {
  final RouterOsService service;
  const BridgeHostsScreen({super.key, required this.service});
  @override
  State<BridgeHostsScreen> createState() => _S();
}

class _S extends State<BridgeHostsScreen> {
  bool l = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await widget.service.bridgeHosts();
    if (mounted) setState(() => l = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Bridge Hosts / FDB'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: l
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final r in rows)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.devices_other),
                    title: Text(r['mac-address'] ?? '—'),
                    subtitle: Text(
                      [r['bridge'], r['on-interface'], r['vid'], r['age']]
                          .whereType<String>()
                          .where((e) => e.isNotEmpty)
                          .join(' • '),
                    ),
                  ),
                ),
            ],
          ),
  );
}
