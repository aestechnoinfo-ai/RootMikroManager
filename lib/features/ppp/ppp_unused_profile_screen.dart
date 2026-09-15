import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppUnusedProfileScreen extends StatefulWidget {
  final RouterOsService service;
  const PppUnusedProfileScreen({super.key, required this.service});
  @override
  State<PppUnusedProfileScreen> createState() => _State();
}

class _State extends State<PppUnusedProfileScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final x = await Future.wait([
      widget.service.pppProfiles(),
      widget.service.pppSecrets(),
      widget.service.pppActive(),
    ]);
    final used = {
      ...x[1].map((e) => e['profile'] ?? ''),
      ...x[2].map((e) => e['profile'] ?? ''),
    };
    rows = x[0].where((e) {
      final n = e['name'] ?? '';
      return n.isNotEmpty &&
          !used.contains(n) &&
          n != 'default' &&
          n != 'default-encryption';
    }).toList();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text('Profils PPP inutilisés (${rows.length})'),
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
                    'Audit non destructif : aucun profil n’est supprimé automatiquement. Les profils par défaut sont exclus.',
                  ),
                ),
              ),
              if (rows.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucun profil PPP inutilisé détecté.'),
                  ),
                ),
              for (final r in rows)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_tree_outlined),
                    title: Text(r['name'] ?? '—'),
                    subtitle: Text(
                      'Local ${r['local-address'] ?? '—'} • Remote ${r['remote-address'] ?? '—'}',
                    ),
                  ),
                ),
            ],
          ),
  );
}
