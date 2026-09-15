import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppSecretConsistencyScreen extends StatefulWidget {
  final RouterOsService service;
  const PppSecretConsistencyScreen({super.key, required this.service});
  @override
  State<PppSecretConsistencyScreen> createState() => _State();
}

class _State extends State<PppSecretConsistencyScreen> {
  bool loading = true;
  List<String> issues = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final rows = await widget.service.pppSecrets();
    final seen = <String, int>{};
    issues = [];
    for (final row in rows) {
      final name = (row['name'] ?? '').trim();
      if (name.isEmpty) {
        issues.add('Secret PPP sans nom.');
        continue;
      }
      seen[name] = (seen[name] ?? 0) + 1;
      if ((row['profile'] ?? '').trim().isEmpty) {
        issues.add('$name : profil non défini.');
      }
      if ((row['service'] ?? '').trim().isEmpty) {
        issues.add('$name : service PPP non défini.');
      }
    }
    for (final entry in seen.entries.where((e) => e.value > 1)) {
      issues.add('${entry.key} : ${entry.value} secrets portent le même nom.');
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cohérence secrets PPP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Cet audit ne révèle jamais les mots de passe PPP.',
                  ),
                ),
              ),
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Secrets PPP cohérents.'),
                  ),
                ),
              for (final issue in issues)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(issue),
                  ),
                ),
            ],
          ),
  );
}
