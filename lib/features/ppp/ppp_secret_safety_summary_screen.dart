import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppSecretSafetySummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const PppSecretSafetySummaryScreen({super.key, required this.service});
  @override
  State<PppSecretSafetySummaryScreen> createState() => _State();
}

class _State extends State<PppSecretSafetySummaryScreen> {
  bool loading = true;
  int secrets = 0, missingProfile = 0, duplicateNames = 0, active = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await Future.wait([
      widget.service.pppSecrets(),
      widget.service.pppProfiles(),
      widget.service.pppActive(),
    ]);
    final rows = x[0], profiles = x[1].map((e) => e['name'] ?? '').toSet();
    final seen = <String>{};
    var dup = 0, miss = 0;
    for (final row in rows) {
      final n = (row['name'] ?? '').trim().toLowerCase();
      if (n.isNotEmpty && !seen.add(n)) dup++;
      final pr = row['profile'] ?? 'default';
      if (!profiles.contains(pr)) miss++;
    }
    secrets = rows.length;
    missingProfile = miss;
    duplicateNames = dup;
    active = x[2].length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Synthèse sécurité PPP'),
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
                  trailing: Text('$secrets'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Sessions actives'),
                  trailing: Text('$active'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Noms dupliqués'),
                  trailing: Text('$duplicateNames'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Profils référencés absents'),
                  trailing: Text('$missingProfile'),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Aucun mot de passe PPP n’est affiché dans cette synthèse.',
                  ),
                ),
              ),
            ],
          ),
  );
}
