import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'scheduler_detail_screen.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';

class SchedulerManagementScreen extends StatefulWidget {
  final RouterOsService service;
  const SchedulerManagementScreen({super.key, required this.service});
  @override
  State<SchedulerManagementScreen> createState() => _State();
}

class _State extends State<SchedulerManagementScreen> {
  final search = TextEditingController();
  String filter = 'all';
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  bool disabled(Map<String, String> r) =>
      r['disabled'] == 'yes' || r['disabled'] == 'true';
  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) {
      if (filter == 'enabled' && disabled(r)) return false;
      if (filter == 'disabled' && !disabled(r)) return false;
      return q.isEmpty || r.values.any((v) => v.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.schedulers();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? r]) async {
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.schedulerEdit,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> action(String a, Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    if (a == 'detail') {
      await AppRouter.pushNamed(
        context,
        AppRoutes.schedulerDetail,
        extra: RequiredRowPayload(r),
      );
      return;
    }
    if (a == 'edit') return edit(r);
    if (a == 'toggle')
      await widget.service.setSchedulerEnabled(id, enabled: disabled(r));
    if (a == 'delete') {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Supprimer ce Scheduler ?'),
              content: Text(
                'Supprimer ${r['name'] ?? 'ce Scheduler'} ? Cette planification ne sera plus exécutée.',
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
      await widget.service.remove('/system/scheduler', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text('Scheduler (${rows.length})'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Nom, on-event, policy, commentaire…',
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('Tous')),
              ButtonSegment(value: 'enabled', label: Text('Actifs')),
              ButtonSegment(value: 'disabled', label: Text('Désactivés')),
            ],
            selected: {filter},
            onSelectionChanged: (v) => setState(() => filter = v.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau Scheduler'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final r = visible[i], off = disabled(r);
                    return Card(
                      child: ListTile(
                        onTap: () => action('detail', r),
                        leading: CircleAvatar(
                          child: Icon(
                            off
                                ? Icons.event_busy_outlined
                                : Icons.event_repeat_outlined,
                          ),
                        ),
                        title: Text(r['name'] ?? '—'),
                        subtitle: Text(
                          [
                            'Next ${r['next-run'] ?? '—'}',
                            'Start ${r['start-time'] ?? '—'}',
                            'Interval ${r['interval'] ?? '0s'}',
                            'Run ${r['run-count'] ?? '0'}',
                          ].join(' • '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) => action(v, r),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'detail',
                              child: Text('Détails'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Modifier'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(off ? 'Activer' : 'Désactiver'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
