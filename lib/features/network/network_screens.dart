import 'package:flutter/material.dart';
import '../../core/routeros/router_session.dart';

class RouterListScreen extends StatefulWidget {
  final String title;
  final Future<List<Map<String, String>>> Function() loader;
  const RouterListScreen({
    super.key,
    required this.title,
    required this.loader,
  });
  @override
  State<RouterListScreen> createState() => _RouterListScreenState();
}

class _RouterListScreenState extends State<RouterListScreen> {
  late Future<List<Map<String, String>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.loader();
  }

  void refresh() {
    setState(() => future = widget.loader());
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: FutureBuilder<List<Map<String, String>>>(
      future: future,
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Erreur : ${s.error}'),
            ),
          );
        final rows = s.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('Aucune donnée'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rows.length,
          itemBuilder: (c, i) {
            final r = rows[i];
            return Card(
              child: ExpansionTile(
                title: Text(r['name'] ?? r['address'] ?? r['.id'] ?? 'Élément'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      r.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class DhcpScreen extends StatelessWidget {
  const DhcpScreen({super.key});
  @override
  Widget build(BuildContext c) => RouterListScreen(
    title: 'DHCP Leases',
    loader: () => RouterSession.instance.service.dhcpLeases(),
  );
}

class InterfacesScreen extends StatelessWidget {
  const InterfacesScreen({super.key});
  @override
  Widget build(BuildContext c) => RouterListScreen(
    title: 'Interfaces',
    loader: () => RouterSession.instance.service.interfaces(),
  );
}

class DnsScreen extends StatelessWidget {
  const DnsScreen({super.key});
  @override
  Widget build(BuildContext c) => RouterListScreen(
    title: 'DNS statique',
    loader: () => RouterSession.instance.service.dnsStatic(),
  );
}

class WirelessScreen extends StatelessWidget {
  const WirelessScreen({super.key});
  @override
  Widget build(BuildContext c) => RouterListScreen(
    title: 'Wireless',
    loader: () => RouterSession.instance.service.wireless(),
  );
}
