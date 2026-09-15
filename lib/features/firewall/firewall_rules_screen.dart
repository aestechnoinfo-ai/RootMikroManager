import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'firewall_safety_analyzer.dart';

class FirewallRulesScreen extends StatefulWidget {
  final RouterOsService service;
  final String path;
  final String title;

  const FirewallRulesScreen({
    super.key,
    required this.service,
    required this.path,
    required this.title,
  });

  @override
  State<FirewallRulesScreen> createState() => _FirewallRulesScreenState();
}

class _FirewallRulesScreenState extends State<FirewallRulesScreen> {
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
    rows = await widget.service.client.print(widget.path);
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> openEditor([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.firewallAdvancedRuleEdit,
      extra: FirewallAdvancedRulePayload(path: widget.path, row: row),
    );
    if (changed == true) await load();
  }

  Future<void> action(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final protected = FirewallSafetyAnalyzer.dynamicOrDummy(row);
    if (action == 'edit') {
      if (!protected) return openEditor(row);
      return;
    }
    if (action == 'duplicate') {
      if (protected) return;
      await widget.service.duplicateFirewallRule(widget.path, row);
    } else if (action == 'move-up' || action == 'move-down') {
      if (protected) return;
      final index = rows.indexWhere((e) => e['.id'] == id);
      final target = action == 'move-up' ? index - 1 : index + 1;
      if (index < 0 || target < 0 || target >= rows.length) return;
      final destinationId = rows[target]['.id'];
      if (destinationId == null) return;
      await widget.service.moveFirewallRule(
        widget.path,
        id,
        destinationId: destinationId,
      );
    } else if (action == 'enable') {
      if (!protected) await widget.service.enable(widget.path, id);
    } else if (action == 'disable') {
      if (!protected) await widget.service.disable(widget.path, id);
    } else if (action == 'reset') {
      await widget.service.resetFirewallRuleCounters(widget.path, id);
    } else if (action == 'delete') {
      if (protected) return;
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer cette règle ?'),
              content: Text(
                '${row['chain'] ?? '—'} → ${row['action'] ?? '—'}\n\n'
                'L’ordre du firewall est significatif. Une suppression peut '
                'modifier immédiatement la sécurité ou la connectivité.',
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
      await widget.service.remove(widget.path, id);
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
              labelText: 'Recherche',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une règle'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final r = visible[i];
                      final disabled =
                          r['disabled'] == 'true' || r['disabled'] == 'yes';
                      final invalid =
                          r['invalid'] == 'true' || r['invalid'] == 'yes';
                      final protected = FirewallSafetyAnalyzer.dynamicOrDummy(
                        r,
                      );
                      return Card(
                        child: ListTile(
                          onTap: protected ? null : () => openEditor(r),
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
                            '${r['chain'] ?? '—'} → ${r['action'] ?? '—'}',
                          ),
                          subtitle: Text(
                            [
                              if ((r['protocol'] ?? '').isNotEmpty)
                                r['protocol']!,
                              if ((r['src-address'] ?? '').isNotEmpty)
                                'src ${r['src-address']}',
                              if ((r['dst-address'] ?? '').isNotEmpty)
                                'dst ${r['dst-address']}',
                              if ((r['dst-port'] ?? '').isNotEmpty)
                                'port ${r['dst-port']}',
                              if ((r['bytes'] ?? '').isNotEmpty)
                                '${r['bytes']} bytes',
                              if ((r['packets'] ?? '').isNotEmpty)
                                '${r['packets']} packets',
                              if ((r['comment'] ?? '').isNotEmpty)
                                r['comment']!,
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => action(v, r),
                            itemBuilder: (_) => [
                              if (!protected)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                              if (!protected)
                                PopupMenuItem(
                                  value: disabled ? 'enable' : 'disable',
                                  child: Text(
                                    disabled ? 'Activer' : 'Désactiver',
                                  ),
                                ),
                              if (!protected)
                                const PopupMenuItem(
                                  value: 'duplicate',
                                  child: Text('Dupliquer désactivée'),
                                ),
                              if (!protected)
                                const PopupMenuItem(
                                  value: 'move-up',
                                  child: Text('Monter'),
                                ),
                              if (!protected)
                                const PopupMenuItem(
                                  value: 'move-down',
                                  child: Text('Descendre'),
                                ),
                              const PopupMenuItem(
                                value: 'reset',
                                child: Text('Reset counters'),
                              ),
                              if (!protected)
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
