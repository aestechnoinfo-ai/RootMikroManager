import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';

class LoggingActionsScreen extends StatefulWidget {
  final RouterOsService service;
  const LoggingActionsScreen({super.key, required this.service});
  @override
  State<LoggingActionsScreen> createState() => _S();
}

class _S extends State<LoggingActionsScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  static const builtIns = {'memory', 'disk', 'echo', 'remote'};
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.loggingActions();
    if (mounted) setState(() => loading = false);
  }

  void note(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> edit([Map<String, String>? r]) async {
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.loggingActionEdit,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> clear(Map<String, String> r) async {
    if (r['target'] != 'memory') return;
    final n = r['name'];
    if (n == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Vider ce buffer ?'),
            content: Text(
              'Effacer les logs mémoire de $n ? Nécessite RouterOS 7.20_ab244 ou plus récent.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Vider'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await widget.service.clearMemoryLogAction(n);
      note('Buffer vidé.');
    } catch (e) {
      note('Commande indisponible : $e');
    }
  }

  Future<void> remove(Map<String, String> r) async {
    if (builtIns.contains(r['name'])) {
      note('Action intégrée protégée.');
      return;
    }
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cette action ?'),
            content: const Text(
              'Les règles qui la référencent peuvent devenir invalides.',
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
      await widget.service.remove('/system/logging/action', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Actions de logging'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une action'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final r in rows)
                      Card(
                        child: ListTile(
                          onTap: () => edit(r),
                          leading: const Icon(Icons.output_outlined),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'Target ${r['target'] ?? '—'}',
                              if ((r['remote-port'] ?? r['remote'] ?? '')
                                  .isNotEmpty)
                                r['remote-port'] ?? r['remote']!,
                              if ((r['vrf'] ?? '').isNotEmpty)
                                'VRF ${r['vrf']}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') edit(r);
                              if (v == 'clear') clear(r);
                              if (v == 'delete') remove(r);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Modifier'),
                              ),
                              if (r['target'] == 'memory')
                                const PopupMenuItem(
                                  value: 'clear',
                                  child: Text('Vider le buffer'),
                                ),
                              if (!builtIns.contains(r['name']))
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer'),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
