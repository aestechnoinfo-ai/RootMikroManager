import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class ScriptJobsScreen extends StatefulWidget {
  final RouterOsService service;
  const ScriptJobsScreen({super.key, required this.service});
  @override
  State<ScriptJobsScreen> createState() => _State();
}

class _State extends State<ScriptJobsScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.scriptJobs();
    if (mounted) setState(() => loading = false);
  }

  Future<void> stop(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Arrêter ce job ?'),
            content: Text(
              'Interrompre le script lancé par ${r['owner'] ?? '—'} ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Arrêter'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await widget.service.stopScriptJob(id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text('Jobs scripts (${rows.length})'),
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
                    'Cette vue affiche uniquement les scripts actuellement en cours d’exécution. Un arrêt force la suppression du job actif.',
                  ),
                ),
              ),
              if (rows.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucun job actif'),
                  ),
                ),
              for (final r in rows)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(r['owner'] ?? 'Script actif'),
                    subtitle: Text(
                      [
                        'Started ${r['started'] ?? '—'}',
                        if ((r['policy'] ?? '').isNotEmpty) r['policy']!,
                      ].join(' • '),
                    ),
                    trailing: IconButton(
                      onPressed: () => stop(r),
                      icon: const Icon(Icons.stop_circle_outlined),
                    ),
                  ),
                ),
            ],
          ),
  );
}
