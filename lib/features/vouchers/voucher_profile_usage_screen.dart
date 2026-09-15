import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VoucherProfileUsageScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherProfileUsageScreen({super.key, required this.service});
  @override
  State<VoucherProfileUsageScreen> createState() => _S();
}

class _S extends State<VoucherProfileUsageScreen> {
  bool loading = true;
  List<Map<String, String>> profiles = [], users = [], active = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Future.wait([
      widget.service.hotspotProfiles(),
      widget.service.hotspotUsers(),
      widget.service.activeUsers(),
    ]);
    profiles = r[0];
    users = r[1];
    active = r[2];
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Utilisation des profils'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final p in profiles)
                Builder(
                  builder: (_) {
                    final n = p['name'] ?? '';
                    final linked = users
                        .where((u) => u['profile'] == n)
                        .toList();
                    final names = linked
                        .map((u) => u['name'])
                        .whereType<String>()
                        .toSet();
                    final online = active
                        .where((a) => names.contains(a['user']))
                        .length;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_tree_outlined),
                        title: Text(n.isEmpty ? '—' : n),
                        subtitle: Text(
                          '${linked.length} ticket(s) • $online actuellement actif(s)',
                        ),
                        trailing: linked.isEmpty
                            ? const Chip(label: Text('Inutilisé'))
                            : null,
                      ),
                    );
                  },
                ),
            ],
          ),
  );
}
