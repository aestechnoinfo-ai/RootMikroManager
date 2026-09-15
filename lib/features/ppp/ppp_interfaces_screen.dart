import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppInterfacesScreen extends StatefulWidget {
  final RouterOsService service;
  const PppInterfacesScreen({super.key, required this.service});
  @override
  State<PppInterfacesScreen> createState() => _PppInterfacesScreenState();
}

class _PppInterfacesScreenState extends State<PppInterfacesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.pppInterfaces();
    if (mounted) setState(() => loading = false);
  }

  String source(Map<String, String> r) =>
      (r['_source-path'] ?? '').replaceAll('/interface/', '');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Interfaces PPP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                final running = r['running'] == 'true' || r['running'] == 'yes';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(running ? Icons.link : Icons.link_off),
                    ),
                    title: Text(r['name'] ?? '—'),
                    subtitle: Text(
                      [
                        source(r),
                        if ((r['user'] ?? '').isNotEmpty) 'User ${r['user']}',
                        if ((r['mtu'] ?? '').isNotEmpty) 'MTU ${r['mtu']}',
                      ].join(' • '),
                    ),
                  ),
                );
              },
            ),
          ),
  );
}
