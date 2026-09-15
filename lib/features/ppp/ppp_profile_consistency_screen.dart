import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppProfileConsistencyScreen extends StatefulWidget {
  final RouterOsService service;
  const PppProfileConsistencyScreen({super.key, required this.service});
  @override
  State<PppProfileConsistencyScreen> createState() => _State();
}

class _State extends State<PppProfileConsistencyScreen> {
  bool loading = true;
  List<String> issues = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final values = await Future.wait([
      widget.service.pppProfiles(),
      widget.service.pppSecrets(),
      widget.service.ipPools(),
    ]);
    final profiles = values[0];
    final secrets = values[1];
    final pools = values[2];
    final profileNames = profiles.map((e) => e['name'] ?? '').toSet();
    final poolNames = pools.map((e) => e['name'] ?? '').toSet();
    issues = [];

    for (final secret in secrets) {
      final name = secret['name'] ?? '—';
      final profile = secret['profile'] ?? '';
      if (profile.isNotEmpty &&
          profile != 'default' &&
          !profileNames.contains(profile)) {
        issues.add('$name : profil PPP "$profile" introuvable.');
      }
    }

    for (final profile in profiles) {
      final name = profile['name'] ?? '—';
      for (final field in ['local-address', 'remote-address']) {
        final value = profile[field] ?? '';
        if (value.isEmpty) continue;
        final looksLikeIp = RegExp(r'^\d{1,3}(\.\d{1,3}){3}').hasMatch(value);
        if (!looksLikeIp && !poolNames.contains(value)) {
          issues.add('$name : $field référence "$value", pool introuvable.');
        }
      }
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cohérence profils PPP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucune incohérence simple détectée.'),
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
