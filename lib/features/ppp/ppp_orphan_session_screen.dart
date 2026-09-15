import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppOrphanSessionScreen extends StatefulWidget {
  final RouterOsService service;
  const PppOrphanSessionScreen({super.key, required this.service});
  @override
  State<PppOrphanSessionScreen> createState() => _State();
}

class _State extends State<PppOrphanSessionScreen> {
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
      widget.service.pppSecrets(),
      widget.service.pppActive(),
    ]);
    final names = x[0].map((e) => e['name'] ?? '').toSet();
    rows = x[1].where((e) => !names.contains(e['name'] ?? '')).toList();
    if (mounted) setState(() => loading = false);
  }

  Future<void> disconnect(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Déconnecter la session ?'),
            content: Text(
              '${r['name'] ?? '—'} ne correspond à aucun secret PPP actuel.',
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
    await widget.service.disconnectPppActive(id);
    await load();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text('Sessions PPP orphelines (${rows.length})'),
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
                    'Une session est signalée ici lorsque son nom ne correspond plus à aucun secret PPP. La déconnexion reste manuelle et confirmée.',
                  ),
                ),
              ),
              if (rows.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucune session orpheline.'),
                  ),
                ),
              for (final r in rows)
                Card(
                  child: ListTile(
                    title: Text(r['name'] ?? '—'),
                    subtitle: Text(
                      '${r['service'] ?? '—'} • ${r['address'] ?? '—'} • ${r['uptime'] ?? '—'}',
                    ),
                    trailing: TextButton(
                      onPressed: () => disconnect(r),
                      child: const Text('Déconnecter'),
                    ),
                  ),
                ),
            ],
          ),
  );
}
