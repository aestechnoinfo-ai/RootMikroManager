import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class ZeroTierPeersScreen extends StatefulWidget {
  final RouterOsService service;
  const ZeroTierPeersScreen({super.key, required this.service});
  @override
  State<ZeroTierPeersScreen> createState() => _S();
}

class _S extends State<ZeroTierPeersScreen> {
  bool l = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await widget.service.zeroTierPeers();
    if (mounted) setState(() => l = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('ZeroTier • Peers')),
    body: l
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final r in rows)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.device_hub_outlined),
                    title: Text(r['zt-address'] ?? 'Peer'),
                    subtitle: Text(
                      [
                        'Role ${r['role'] ?? '—'}',
                        'Latency ${r['latency'] ?? '—'}',
                        if ((r['path'] ?? '').isNotEmpty) r['path']!,
                      ].join(' • '),
                    ),
                  ),
                ),
            ],
          ),
  );
}
