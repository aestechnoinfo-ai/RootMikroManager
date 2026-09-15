import 'package:flutter/material.dart';
import 'routing_policy_analyzer.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class RoutingTablesScreen extends StatefulWidget {
  final RouterOsService service;
  const RoutingTablesScreen({super.key, required this.service});
  @override
  State<RoutingTablesScreen> createState() => _State();
}

class _State extends State<RoutingTablesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [], rules = [], routes = [], ipv6Routes = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.routingTablesAdvanced(),
      widget.service.routingRules(),
      widget.service.ipRoutes(),
      widget.service.ipv6Routes(),
    ]);
    rows = x[0];
    rules = x[1];
    routes = x[2];
    ipv6Routes = x[3];
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? r]) async {
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.routingTableEdit,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> removeTable(Map<String, String> r) async {
    final name = r['name'] ?? '', id = r['.id'];
    if (name == 'main' || id == null) return;
    final issues = RoutingPolicyAnalyzer.tableDelete(
      name: name,
      ipv4Routes: routes,
      ipv6Routes: ipv6Routes,
      rules: rules,
    );
    if (issues.any((e) => e.critical)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(issues.map((e) => e.message).join('\n'))),
      );
      return;
    }
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Supprimer la table $name ?'),
            content: const Text(
              'Cette action est autorisée uniquement parce qu’aucune dépendance simple n’a été détectée.',
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
      await widget.service.remove('/routing/table', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Tables de routage'),
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
              label: const Text('Nouvelle table'),
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
                      Builder(
                        builder: (_) {
                          final n = r['name'] ?? '';
                          final rc = rules.where((e) => e['table'] == n).length;
                          final rtc = routes
                              .where((e) => e['routing-table'] == n)
                              .length;
                          return Card(
                            child: ListTile(
                              onTap: () => edit(r),
                              leading: const Icon(Icons.table_rows_outlined),
                              title: Text(n.isEmpty ? '—' : n),
                              subtitle: Text(
                                'FIB ${r['fib'] ?? '—'} • $rc règle(s) • $rtc route(s)',
                              ),
                              trailing: n == 'main'
                                  ? const Chip(label: Text('main'))
                                  : IconButton(
                                      onPressed: () => removeTable(r),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
