import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppoeServerScreen extends StatefulWidget {
  final RouterOsService service;
  const PppoeServerScreen({super.key, required this.service});
  @override
  State<PppoeServerScreen> createState() => _PppoeServerScreenState();
}

class _PppoeServerScreenState extends State<PppoeServerScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.pppoeServerSettings();
    if (mounted) setState(() => loading = false);
  }

  Future<void> toggle(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final disabled = row['disabled'] == 'yes' || row['disabled'] == 'true';
    if (disabled) {
      await widget.service.enable('/interface/pppoe-server/server', id);
    } else {
      await widget.service.disable('/interface/pppoe-server/server', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Serveurs PPPoE'),
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
                final disabled =
                    r['disabled'] == 'yes' || r['disabled'] == 'true';
                return Card(
                  child: ListTile(
                    leading: Icon(
                      disabled ? Icons.pause_circle : Icons.play_circle,
                    ),
                    title: Text(r['service-name'] ?? 'PPPoE'),
                    subtitle: Text(
                      [
                        'Interface ${r['interface'] ?? '—'}',
                        'Profil ${r['default-profile'] ?? '—'}',
                        if ((r['max-mtu'] ?? '').isNotEmpty)
                          'MTU ${r['max-mtu']}',
                        if ((r['max-mru'] ?? '').isNotEmpty)
                          'MRU ${r['max-mru']}',
                        if ((r['authentication'] ?? '').isNotEmpty)
                          'Auth ${r['authentication']}',
                      ].join(' • '),
                    ),
                    trailing: Switch(
                      value: !disabled,
                      onChanged: (_) => toggle(r),
                    ),
                  ),
                );
              },
            ),
          ),
  );
}
