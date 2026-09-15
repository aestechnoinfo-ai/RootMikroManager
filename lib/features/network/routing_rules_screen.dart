import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class RoutingRulesScreen extends StatefulWidget {
  final RouterOsService service;
  const RoutingRulesScreen({super.key, required this.service});
  @override
  State<RoutingRulesScreen> createState() => _State();
}

class _State extends State<RoutingRulesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.routingRules();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? r]) async {
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.routingRuleEdit,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> toggle(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    await widget.service.set('/routing/rule', id, {
      'disabled': r['disabled'] == 'yes' ? 'no' : 'yes',
    });
    await load();
  }

  Future<void> removeRule(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cette règle ?'),
            content: Text(
              '${r['src-address'] ?? 'any'} → ${r['dst-address'] ?? 'any'} • ${r['action'] ?? 'lookup'}',
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
      await widget.service.remove('/routing/rule', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Policy Routing Rules'),
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
              label: const Text('Ajouter une règle'),
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
                          leading: Icon(
                            r['disabled'] == 'yes'
                                ? Icons.pause_circle_outline
                                : Icons.alt_route,
                          ),
                          title: Text(
                            '${r['action'] ?? 'lookup'}${(r['table'] ?? '').isEmpty ? '' : ' → ${r['table']}'}',
                          ),
                          subtitle: Text(
                            [
                              'src ${r['src-address'] ?? 'any'}',
                              'dst ${r['dst-address'] ?? 'any'}',
                              if ((r['interface'] ?? '').isNotEmpty)
                                'in ${r['interface']}',
                              if ((r['comment'] ?? '').isNotEmpty)
                                r['comment']!,
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'toggle') toggle(r);
                              if (v == 'delete') removeRule(r);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  r['disabled'] == 'yes'
                                      ? 'Activer'
                                      : 'Désactiver',
                                ),
                              ),
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
