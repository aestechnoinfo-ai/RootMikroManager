import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VoucherDuplicateAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherDuplicateAuditScreen({super.key, required this.service});
  @override
  State<VoucherDuplicateAuditScreen> createState() => _S();
}

class _S extends State<VoucherDuplicateAuditScreen> {
  bool loading = true;
  List<Map<String, String>> users = [];
  Map<String, int> counts = {};
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    users = await widget.service.hotspotUsers();
    final m = <String, int>{};
    for (final u in users) {
      final n = u['name'] ?? '';
      if (n.isNotEmpty) m[n] = (m[n] ?? 0) + 1;
    }
    counts = m;
    if (mounted) setState(() => loading = false);
  }

  List<String> get duplicates =>
      (counts.entries.where((e) => e.value > 1).map((e) => e.key).toList()
        ..sort());
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Audit doublons vouchers'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Tickets analysés'),
                  trailing: Text('${users.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Identifiants dupliqués'),
                  trailing: Text('${duplicates.length}'),
                ),
              ),
              if (duplicates.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucun doublon détecté'),
                  ),
                ),
              for (final n in duplicates)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(n),
                    subtitle: Text(
                      '${counts[n]} entrées portent ce même identifiant',
                    ),
                  ),
                ),
            ],
          ),
  );
}
