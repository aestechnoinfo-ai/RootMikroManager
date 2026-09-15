import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SchedulerLinkageScreen extends StatefulWidget {
  final RouterOsService service;
  const SchedulerLinkageScreen({super.key, required this.service});
  @override
  State<SchedulerLinkageScreen> createState() => _State();
}

class _State extends State<SchedulerLinkageScreen> {
  bool loading = true;
  List<Map<String, String>> scripts = [], schedulers = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.scripts(),
      widget.service.schedulers(),
    ]);
    scripts = x[0];
    schedulers = x[1];
    if (mounted) setState(() => loading = false);
  }

  Set<String> p(String? x) => {
    ...(x ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
  };
  Map<String, String>? target(Map<String, String> s) {
    final e = (s['on-event'] ?? '').trim();
    for (final r in scripts) {
      final n = r['name'] ?? '';
      if (e == n ||
          e.contains('/system script run $n') ||
          e.contains('/system/script/run $n'))
        return r;
    }
    return null;
  }

  String relation(Map<String, String> s) {
    final r = target(s);
    return r == null ? 'Commande / source inline' : 'Script : ${r['name']}';
  }

  String risk(Map<String, String> s) {
    final r = target(s);
    if (r == null) return '';
    final sp = p(r['policy']), sch = p(s['policy']);
    final missing = sp.difference(sch);
    if (missing.isEmpty) return '';
    return 'Policies script absentes du Scheduler : ${missing.join(', ')}';
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Scripts ↔ Scheduler'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Inventaire'),
                  subtitle: Text(
                    '${scripts.length} scripts • ${schedulers.length} schedulers',
                  ),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'L’analyse de policies est conservative : la méthode exacte d’appel influence les permissions effectives. Une différence n’implique pas toujours un échec, mais mérite vérification.',
                  ),
                ),
              ),
              for (final s in schedulers)
                Card(
                  child: ListTile(
                    leading: Icon(
                      risk(s).isEmpty
                          ? Icons.account_tree_outlined
                          : Icons.warning_amber_outlined,
                    ),
                    title: Text(s['name'] ?? 'Scheduler'),
                    subtitle: Text(
                      [relation(s), if (risk(s).isNotEmpty) risk(s)].join('\n'),
                    ),
                    trailing: Text(s['interval'] ?? '0s'),
                  ),
                ),
            ],
          ),
  );
}
