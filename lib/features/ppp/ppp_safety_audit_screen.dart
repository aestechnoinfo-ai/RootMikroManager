import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppSafetyAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const PppSafetyAuditScreen({super.key, required this.service});
  @override
  State<PppSafetyAuditScreen> createState() => _S();
}

class _S extends State<PppSafetyAuditScreen> {
  bool loading = true;
  List<Map<String, String>> secrets = [],
      profiles = [],
      active = [],
      pools = [];
  List<String> issues = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.pppSecrets(),
      widget.service.pppProfiles(),
      widget.service.pppActive(),
      widget.service.ipPools(),
    ]);
    secrets = x[0];
    profiles = x[1];
    active = x[2];
    pools = x[3];
    analyze();
    if (mounted) setState(() => loading = false);
  }

  void analyze() {
    issues = [];
    final names = <String, int>{};
    for (final s in secrets) {
      final n = s['name'] ?? '';
      if (n.isNotEmpty) names[n] = (names[n] ?? 0) + 1;
    }
    for (final e in names.entries.where((e) => e.value > 1))
      issues.add('Secret dupliqué : ${e.key} (${e.value} fois).');
    final profileNames = profiles.map((e) => e['name'] ?? '').toSet();
    for (final s in secrets) {
      final p = s['profile'] ?? 'default';
      if (p.isNotEmpty && !profileNames.contains(p))
        issues.add('${s['name'] ?? 'Secret'} référence un profil absent : $p.');
    }
    final poolNames = pools.map((e) => e['name'] ?? '').toSet();
    for (final p in profiles) {
      final remote = p['remote-address'] ?? '';
      if (remote.isNotEmpty &&
          !remote.contains('.') &&
          !remote.contains(':') &&
          !poolNames.contains(remote))
        issues.add(
          'Profil ${p['name'] ?? '—'} : pool distant introuvable « $remote ».',
        );
    }
    final activeNames = active.map((e) => e['name'] ?? '').toSet();
    for (final n in activeNames) {
      if (n.isNotEmpty && !names.containsKey(n))
        issues.add('Session active « $n » sans secret PPP correspondant.');
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Audit PPP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Secrets'),
                  trailing: Text('${secrets.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Profils'),
                  trailing: Text('${profiles.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Sessions actives'),
                  trailing: Text('${active.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Pools IP'),
                  trailing: Text('${pools.length}'),
                ),
              ),
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucune incohérence simple détectée.'),
                  ),
                ),
              for (final x in issues)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(x),
                  ),
                ),
            ],
          ),
  );
}
