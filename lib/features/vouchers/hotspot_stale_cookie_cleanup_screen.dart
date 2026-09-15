import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotStaleCookieCleanupScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotStaleCookieCleanupScreen({super.key, required this.service});
  @override
  State<HotspotStaleCookieCleanupScreen> createState() => _S();
}

class _S extends State<HotspotStaleCookieCleanupScreen> {
  bool loading = true;
  List<Map<String, String>> stale = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.hotspotUsers(),
      widget.service.hotspotCookies(),
    ]);
    final names = x[0].map((e) => e['name'] ?? '').toSet();
    stale = x[1].where((c) => !names.contains(c['user'] ?? '')).toList();
    if (mounted) setState(() => loading = false);
  }

  Future<void> clean() async {
    if (stale.isEmpty) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer les cookies orphelins ?'),
            content: Text(
              '${stale.length} cookie(s) référencent des tickets qui n’existent plus. Cette opération aide le client à retrouver la page de connexion captive.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    for (final r in List<Map<String, String>>.from(stale)) {
      final id = r['.id'];
      if (id != null) await widget.service.remove('/ip/hotspot/cookie', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Cookies Hotspot orphelins'),
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
                    'Un cookie Hotspot conservé après expiration/suppression d’un ticket peut perturber le retour vers la page Login du portail captif.',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Cookies orphelins'),
                  trailing: Text('${stale.length}'),
                ),
              ),
              for (final r in stale)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cookie_outlined),
                    title: Text(r['user'] ?? '—'),
                    subtitle: Text(
                      '${r['mac-address'] ?? '—'} • expires ${r['expires-in'] ?? '—'}',
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: stale.isEmpty ? null : clean,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Supprimer les cookies orphelins'),
              ),
            ],
          ),
  );
}
