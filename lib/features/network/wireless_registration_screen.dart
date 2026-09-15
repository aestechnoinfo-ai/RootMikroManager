import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class WirelessRegistrationScreen extends StatefulWidget {
  final RouterOsService service;
  const WirelessRegistrationScreen({super.key, required this.service});
  @override
  State<WirelessRegistrationScreen> createState() =>
      _WirelessRegistrationScreenState();
}

class _WirelessRegistrationScreenState
    extends State<WirelessRegistrationScreen> {
  final search = TextEditingController();
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.wirelessRegistrationsAll();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> disconnect(Map<String, String> r) async {
    final id = r['.id'];
    final path = r['_path'];
    if (id == null || path == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Déconnecter ce client ?'),
            content: Text(
              '${r['mac-address'] ?? r['station-mac'] ?? 'Client'}\n'
              'Le client pourra tenter de se reconnecter immédiatement si les règles Wi‑Fi l’autorisent.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Déconnecter'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await widget.service.remove(path, id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Clients Wi‑Fi (${rows.length})'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'MAC, interface, signal, SSID…',
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final r = visible[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.devices_outlined),
                          ),
                          title: Text(
                            r['mac-address'] ?? r['station-mac'] ?? 'Client',
                          ),
                          subtitle: Text(
                            [
                              r['_backend'] ?? '',
                              if ((r['interface'] ?? '').isNotEmpty)
                                r['interface']!,
                              if ((r['signal-strength'] ?? r['signal'] ?? '')
                                  .isNotEmpty)
                                'Signal ${r['signal-strength'] ?? r['signal']}',
                              if ((r['tx-rate'] ?? '').isNotEmpty)
                                'TX ${r['tx-rate']}',
                              if ((r['rx-rate'] ?? '').isNotEmpty)
                                'RX ${r['rx-rate']}',
                              if ((r['uptime'] ?? '').isNotEmpty)
                                'Uptime ${r['uptime']}',
                            ].where((e) => e.isNotEmpty).join(' • '),
                          ),
                          trailing: IconButton(
                            tooltip: 'Déconnecter',
                            onPressed: () => disconnect(r),
                            icon: const Icon(Icons.link_off),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
