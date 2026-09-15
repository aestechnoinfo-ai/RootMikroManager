import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class WireGuardInterfacesScreen extends StatefulWidget {
  final RouterOsService service;
  const WireGuardInterfacesScreen({super.key, required this.service});
  @override
  State<WireGuardInterfacesScreen> createState() => _S();
}

class _S extends State<WireGuardInterfacesScreen> {
  bool l = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await widget.service.wireGuardInterfaces();
    if (mounted) setState(() => l = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('WireGuard • Interfaces'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: l
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Les clés privées ne sont jamais affichées par RootMikroManager.',
                  ),
                ),
              ),
              for (final r in rows)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.vpn_key_outlined),
                    title: Text(r['name'] ?? '—'),
                    subtitle: Text(
                      [
                        'Port ${r['listen-port'] ?? 'auto'}',
                        'MTU ${r['mtu'] ?? '—'}',
                        if ((r['public-key'] ?? '').isNotEmpty)
                          'Public key disponible',
                      ].join(' • '),
                    ),
                  ),
                ),
            ],
          ),
  );
}
