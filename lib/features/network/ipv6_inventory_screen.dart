import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class Ipv6InventoryScreen extends StatefulWidget {
  final RouterOsService service;
  const Ipv6InventoryScreen({super.key, required this.service});
  @override
  State<Ipv6InventoryScreen> createState() => _S();
}

class _S extends State<Ipv6InventoryScreen> {
  bool loading = true;
  List<Map<String, String>> a = [], r = [], n = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await Future.wait([
      widget.service.ipv6Addresses(),
      widget.service.ipv6Routes(),
      widget.service.ipv6Neighbors(),
    ]);
    a = x[0];
    r = x[1];
    n = x[2];
    if (mounted) setState(() => loading = false);
  }

  Widget s(String t, List<Map<String, String>> x, IconData i, String k) => Card(
    child: ExpansionTile(
      leading: Icon(i),
      title: Text('$t (${x.length})'),
      children: [
        for (final e in x)
          ListTile(
            title: Text(e[k] ?? '—'),
            subtitle: Text(
              e.entries
                  .where((z) => z.key != '.id' && z.key != k)
                  .take(4)
                  .map((z) => '${z.key}: ${z.value}')
                  .join(' • '),
            ),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('IPv6 • Inventaire')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              s('Adresses', a, Icons.language, 'address'),
              s('Routes', r, Icons.route, 'dst-address'),
              s('Neighbors', n, Icons.device_hub, 'address'),
            ],
          ),
  );
}
