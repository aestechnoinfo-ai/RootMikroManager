import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppProfileUsageScreen extends StatefulWidget {
  final RouterOsService service;
  const PppProfileUsageScreen({super.key, required this.service});
  @override
  State<PppProfileUsageScreen> createState() => _S();
}

class _S extends State<PppProfileUsageScreen> {
  bool loading = true;
  List<Map<String, String>> profiles = [], secrets = [], active = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await Future.wait([
      widget.service.pppProfiles(),
      widget.service.pppSecrets(),
      widget.service.pppActive(),
    ]);
    profiles = x[0];
    secrets = x[1];
    active = x[2];
    if (mounted) setState(() => loading = false);
  }

  int countSecrets(String p) =>
      secrets.where((e) => (e['profile'] ?? 'default') == p).length;
  int countActive(String p) {
    final names = secrets
        .where((e) => (e['profile'] ?? 'default') == p)
        .map((e) => e['name'])
        .toSet();
    return active.where((e) => names.contains(e['name'])).length;
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Utilisation des profils PPP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final p in profiles)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.tune_outlined),
                    title: Text(p['name'] ?? '—'),
                    subtitle: Text(
                      'Secrets ${countSecrets(p['name'] ?? '')} • Actifs ${countActive(p['name'] ?? '')}\nPool ${p['remote-address'] ?? '—'} • Débit ${p['rate-limit'] ?? '—'}',
                    ),
                  ),
                ),
            ],
          ),
  );
}
