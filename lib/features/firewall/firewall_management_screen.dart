import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/router_session.dart';
import 'firewall_safety_analyzer.dart';

class FirewallManagementScreen extends StatefulWidget {
  final String title;
  final String path;

  const FirewallManagementScreen({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  State<FirewallManagementScreen> createState() =>
      _FirewallManagementScreenState();
}

class _FirewallManagementScreenState extends State<FirewallManagementScreen> {
  final search = TextEditingController();
  List<Map<String, String>> rows = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      rows = await RouterSession.instance.service.client.print(widget.path);
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> editor([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.firewallRuleEdit,
      extra: FirewallRulePayload(
        path: widget.path,
        title: widget.title,
        row: row,
      ),
    );
    if (changed == true) await load();
  }

  Future<void> action(String value, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final service = RouterSession.instance.service;

    final protected = FirewallSafetyAnalyzer.dynamicOrDummy(row);
    if (value == 'edit') {
      if (!protected) return editor(row);
      return;
    }
    if (value == 'duplicate' && !protected) {
      await service.duplicateFirewallRule(widget.path, row);
    }
    if (value == 'enable' && !protected) await service.enable(widget.path, id);
    if (value == 'disable' && !protected)
      await service.disable(widget.path, id);
    if (value == 'delete') {
      if (protected) return;
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Supprimer la règle ?'),
              content: Text(row['comment'] ?? 'Cette action est définitive.'),
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
      await service.remove(widget.path, id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
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
              labelText: 'Rechercher',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => editor(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une règle'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final row = visible[i];
                      final disabled =
                          row['disabled'] == 'true' || row['disabled'] == 'yes';
                      final invalid =
                          row['invalid'] == 'true' || row['invalid'] == 'yes';
                      final protected = FirewallSafetyAnalyzer.dynamicOrDummy(
                        row,
                      );
                      return Card(
                        child: ListTile(
                          onTap: protected ? null : () => editor(row),
                          leading: CircleAvatar(
                            child: Icon(
                              invalid
                                  ? Icons.error_outline
                                  : disabled
                                  ? Icons.pause
                                  : Icons.shield_outlined,
                            ),
                          ),
                          title: Text(
                            '${row['chain'] ?? '—'} → ${row['action'] ?? '—'}',
                          ),
                          subtitle: Text(
                            [
                              if ((row['protocol'] ?? '').isNotEmpty)
                                row['protocol']!,
                              if ((row['src-address'] ?? '').isNotEmpty)
                                'src ${row['src-address']}',
                              if ((row['dst-address'] ?? '').isNotEmpty)
                                'dst ${row['dst-address']}',
                              if ((row['dst-port'] ?? '').isNotEmpty)
                                'port ${row['dst-port']}',
                              if ((row['bytes'] ?? '').isNotEmpty)
                                '${row['bytes']} bytes',
                              if ((row['packets'] ?? '').isNotEmpty)
                                '${row['packets']} packets',
                              if ((row['comment'] ?? '').isNotEmpty)
                                row['comment']!,
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => action(v, row),
                            itemBuilder: (_) => [
                              if (!protected)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                              if (!protected)
                                const PopupMenuItem(
                                  value: 'duplicate',
                                  child: Text('Dupliquer désactivée'),
                                ),
                              PopupMenuItem(
                                value: disabled ? 'enable' : 'disable',
                                child: Text(
                                  disabled ? 'Activer' : 'Désactiver',
                                ),
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
