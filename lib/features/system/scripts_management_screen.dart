import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class ScriptsManagementScreen extends StatefulWidget {
  final RouterOsService service;
  const ScriptsManagementScreen({super.key, required this.service});
  @override
  State<ScriptsManagementScreen> createState() => _State();
}

class _State extends State<ScriptsManagementScreen> {
  final search = TextEditingController();
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.scripts();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return q.isEmpty
        ? rows
        : rows
              .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
              .toList();
  }

  Future<void> edit([Map<String, String>? r]) async {
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.scriptEdit,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> run(
    Map<String, String> r, {
    required bool scriptPermissions,
  }) async {
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Exécuter ${r['name'] ?? 'ce script'} ?'),
            content: Text(
              scriptPermissions
                  ? 'Exécution avec les permissions déclarées par le script.'
                  : 'Exécution avec les permissions de l’utilisateur RouterOS actuellement connecté.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exécuter'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await widget.service.runSystemScriptAdvanced(
        id,
        useScriptPermissions: scriptPermissions,
      );
      note('Script exécuté.');
      await load();
    } catch (e) {
      note('$e');
    }
  }

  Future<void> remove(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer ce script ?'),
            content: Text(
              'Supprimer ${r['name'] ?? 'ce script'} ? Les schedulers qui le référencent pourront échouer.',
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
    if (ok) {
      await widget.service.remove('/system/script', id);
      await load();
    }
  }

  void note(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text('Scripts (${rows.length})'),
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
              labelText: 'Nom, owner, policy, commentaire…',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau script'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final r = visible[i];
                    return Card(
                      child: ListTile(
                        onTap: () => AppRouter.pushNamed(
                          context,
                          AppRoutes.scriptDetail,
                          extra: RequiredRowPayload(r),
                        ),
                        leading: const CircleAvatar(child: Icon(Icons.code)),
                        title: Text(r['name'] ?? '—'),
                        subtitle: Text(
                          [
                            if ((r['owner'] ?? '').isNotEmpty)
                              'Owner ${r['owner']}',
                            'Run ${r['run-count'] ?? '0'}',
                            if ((r['last-started'] ?? '').isNotEmpty)
                              'Last ${r['last-started']}',
                            if ((r['policy'] ?? '').isNotEmpty) r['policy']!,
                          ].join(' • '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'run-user')
                              run(r, scriptPermissions: false);
                            if (v == 'run-script')
                              run(r, scriptPermissions: true);
                            if (v == 'edit') edit(r);
                            if (v == 'delete') remove(r);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'run-user',
                              child: Text('Exécuter • permissions utilisateur'),
                            ),
                            PopupMenuItem(
                              value: 'run-script',
                              child: Text('Exécuter • permissions script'),
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
