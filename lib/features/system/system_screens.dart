import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/router_session.dart';
import '../../core/constants/rootmikromanager_markers.dart';
import '../logs/log_visual_style.dart';
import '../logs/router_log_actions_menu.dart';
import 'system_script_editor_screen.dart';
import 'system_scheduler_editor_screen.dart';

class ScriptsScreen extends StatefulWidget {
  const ScriptsScreen({super.key});
  @override
  State<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends State<ScriptsScreen> {
  final search = TextEditingController();
  List<Map<String, String>> rows = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
    load();
  }

  bool reportRow(Map<String, String> r) =>
      (r['comment'] ?? '').toLowerCase() ==
      RootMikroManagerMarkers.reportScriptComment;

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await RouterSession.instance.service.scripts();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get shown {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where(
          (r) => [
            r['name'],
            r['comment'],
            r['policy'],
            r['owner'],
            r['source'],
          ].any((v) => (v ?? '').toLowerCase().contains(q)),
        )
        .toList();
  }

  Future<void> run(Map<String, String> row) async {
    if (reportRow(row)) {
      _msg('Entrée Selling Report protégée.');
      return;
    }
    final id = row['.id'];
    if (id == null) return;
    try {
      await RouterSession.instance.service.runSystemScript(id);
      _msg('Script exécuté.');
    } catch (e) {
      _msg('$e');
    }
  }

  Future<void> edit([Map<String, String>? row]) async {
    if (row != null && reportRow(row)) {
      _msg(
        'Cette entrée appartient au Selling Report RootMikroManager et ne peut pas être modifiée ici.',
      );
      return;
    }
    final name = TextEditingController(text: row?['name'] ?? '');
    final source = TextEditingController(text: row?['source'] ?? '');
    final policy = TextEditingController(text: row?['policy'] ?? '');
    final comment = TextEditingController(text: row?['comment'] ?? '');
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(row == null ? 'Ajouter script' : 'Modifier script'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: source,
                    minLines: 6,
                    maxLines: 14,
                    decoration: const InputDecoration(labelText: 'Source'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: policy,
                    decoration: const InputDecoration(labelText: 'Policy'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: comment,
                    decoration: const InputDecoration(labelText: 'Comment'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      final values = <String, String>{
        'name': name.text.trim(),
        'source': source.text,
        if (policy.text.trim().isNotEmpty) 'policy': policy.text.trim(),
        if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
      };
      if (row == null)
        await RouterSession.instance.service.add('/system/script', values);
      else
        await RouterSession.instance.service.set(
          '/system/script',
          row['.id']!,
          values,
        );
      await load();
    }
    name.dispose();
    source.dispose();
    policy.dispose();
    comment.dispose();
  }

  Future<void> remove(Map<String, String> row) async {
    if (reportRow(row)) {
      _msg(
        'Suppression bloquée : utilise Rapports > Selling Report > Remove Data.',
      );
      return;
    }
    final id = row['.id'];
    if (id == null) return;
    final ok = await _confirm(
      'Supprimer le script « ${row['name'] ?? 'Sans nom'} » ?',
    );
    if (!ok) return;
    await RouterSession.instance.service.remove('/system/script', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Scripts (${rows.length})'),
      actions: [
        IconButton(
          onPressed: loading ? null : () => edit(),
          icon: const Icon(Icons.add),
          tooltip: 'Ajouter',
        ),
        IconButton(
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                ...shown.map((r) {
                  final protected = reportRow(r);
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        protected
                            ? Icons.receipt_long_outlined
                            : Icons.terminal_outlined,
                      ),
                      title: Text(r['name'] ?? 'Sans nom'),
                      subtitle: Text(
                        [
                          if ((r['comment'] ?? '').isNotEmpty)
                            'Comment: ${r['comment']}',
                          if ((r['policy'] ?? '').isNotEmpty)
                            'Policy: ${r['policy']}',
                          if (protected)
                            'Selling Report RootMikroManager — protégé',
                        ].join(' • '),
                      ),
                      onTap: protected ? null : () => edit(r),
                      trailing: protected
                          ? const Icon(Icons.lock_outline)
                          : PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'run')
                                  run(r);
                                else if (v == 'edit')
                                  edit(r);
                                else if (v == 'delete')
                                  remove(r);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'run',
                                  child: Text('Exécuter'),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer'),
                                ),
                              ],
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
  );

  Future<bool> _confirm(String m) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirmation'),
          content: Text(m),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ) ??
      false;
  void _refresh() {
    if (mounted) setState(() {});
  }

  void _msg(String m) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }
}

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});
  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  Future<void> editScheduler([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.schedulerEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  final search = TextEditingController();
  List<Map<String, String>> rows = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await RouterSession.instance.service.schedulers();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  bool managed(Map<String, String> r) =>
      (r['comment'] ?? '').startsWith('Monitor Profile ');
  List<Map<String, String>> get shown {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where(
          (r) => [
            r['name'],
            r['start-date'],
            r['start-time'],
            r['interval'],
            r['next-run'],
            r['run-count'],
            r['comment'],
          ].any((v) => (v ?? '').toLowerCase().contains(q)),
        )
        .toList();
  }

  Future<void> toggle(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final disabled = r['disabled'] == 'true' || r['disabled'] == 'yes';
    try {
      await RouterSession.instance.service.setSchedulerEnabled(
        id,
        enabled: disabled,
      );
      await load();
    } catch (e) {
      _msg('$e');
    }
  }

  Future<void> remove(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final msg = managed(r)
        ? 'Ce scheduler surveille un profil Hotspot RootMikroManager. Le supprimer peut désactiver son expiration automatique. Continuer ?'
        : 'Supprimer le scheduler « ${r['name'] ?? 'Sans nom'} » ?';
    if (!await _confirm(msg)) return;
    try {
      await RouterSession.instance.service.remove('/system/scheduler', id);
      await load();
    } catch (e) {
      _msg('$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('System Scheduler (${rows.length})'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                ...shown.map((r) {
                  final disabled =
                      r['disabled'] == 'true' || r['disabled'] == 'yes';
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        disabled
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined,
                      ),
                      title: Text(r['name'] ?? 'Sans nom'),
                      subtitle: Text(
                        [
                          'Start Date: ${r['start-date'] ?? '—'}',
                          'Start Time: ${r['start-time'] ?? '—'}',
                          'Interval: ${r['interval'] ?? '—'}',
                          'Next Run: ${r['next-run'] ?? '—'}',
                          'Run Count: ${r['run-count'] ?? '0'}',
                          if ((r['comment'] ?? '').isNotEmpty)
                            'Comment: ${r['comment']}',
                          if (managed(r)) 'Scheduler profil Hotspot',
                        ].join(' • '),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'toggle')
                            toggle(r);
                          else if (v == 'delete')
                            remove(r);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(disabled ? 'Activer' : 'Désactiver'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Supprimer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
  );
  Future<bool> _confirm(String m) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirmation'),
          content: Text(m),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ) ??
      false;
  void _refresh() {
    if (mounted) setState(() {});
  }

  void _msg(String m) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }
}

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final search = TextEditingController();
  List<Map<String, String>> rows = [];
  bool loading = true;
  String? error;
  String topic = 'all';
  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await RouterSession.instance.service.logs();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  List<String> get topics {
    final s = <String>{};
    for (final r in rows) {
      for (final t in (r['topics'] ?? '').split(',')) {
        if (t.trim().isNotEmpty) s.add(t.trim());
      }
    }
    final l = s.toList()..sort();
    return l;
  }

  List<Map<String, String>> get shown {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) {
      final mt =
          topic == 'all' ||
          (r['topics'] ?? '').split(',').map((e) => e.trim()).contains(topic);
      final mq =
          q.isEmpty ||
          [
            r['time'],
            r['topics'],
            r['message'],
          ].any((v) => (v ?? '').toLowerCase().contains(q));
      return mt && mq;
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Logs (${rows.length})'),
      actions: [
        RouterLogActionsMenu(
          service: RouterSession.instance.service,
          onChanged: load,
        ),
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    labelText: 'Recherche',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(isExpanded: true, 
                  value: topic,
                  decoration: const InputDecoration(labelText: 'Topic'),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Tous les topics'),
                    ),
                    ...topics.map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    ),
                  ],
                  onChanged: (v) => setState(() => topic = v ?? 'all'),
                ),
                const SizedBox(height: 10),
                ...shown.map((r) {
                  final style = LogVisualStyle.fromRouterOs(r);
                  return Card(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: style.color, width: 4),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: style.color.withValues(alpha: 0.12),
                          child: Icon(style.icon, color: style.color),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(r['topics'] ?? 'Log')),
                            Text(
                              style.label,
                              style: TextStyle(
                                color: style.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(r['message'] ?? ''),
                        trailing: Text(
                          r['time'] ?? '',
                          style: TextStyle(
                            color: style.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
  );
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }
}
