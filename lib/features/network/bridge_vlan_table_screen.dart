import 'package:flutter/material.dart';

import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'bridge_vlan_validator.dart';

class BridgeVlanTableScreen extends StatefulWidget {
  final RouterOsService service;
  const BridgeVlanTableScreen({super.key, required this.service});

  @override
  State<BridgeVlanTableScreen> createState() => _BridgeVlanTableScreenState();
}

class _BridgeVlanTableScreenState extends State<BridgeVlanTableScreen> {
  final search = TextEditingController();
  bool loading = true;
  bool showDynamic = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
    load();
  }

  void _refresh() => setState(() {});

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.bridgeVlans();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) {
      final dynamic = r['dynamic'] == 'yes' || r['dynamic'] == 'true';
      if (!showDynamic && dynamic) return false;
      if (q.isNotEmpty && !r.values.any((v) => v.toLowerCase().contains(q)))
        return false;
      return true;
    }).toList();
  }

  Future<void> edit([Map<String, String>? row]) async {
    if (row?['dynamic'] == 'yes' || row?['dynamic'] == 'true') return;
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.bridgeVlanEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> removeEntry(Map<String, String> row) async {
    final dynamic = row['dynamic'] == 'yes' || row['dynamic'] == 'true';
    if (dynamic) return;
    final id = row['.id'];
    if (id == null) return;
    final bridge = row['bridge'] ?? '';
    final vlans = row['vlan-ids'] ?? '';
    final tagged = BridgeVlanValidator.splitMembers(row['tagged']);
    final untagged = BridgeVlanValidator.splitMembers(row['untagged']);
    final cpuMember = tagged.contains(bridge) || untagged.contains(bridge);
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cette entrée VLAN ?'),
            content: Text(
              '${bridge.isEmpty ? 'Bridge' : bridge} • VLAN $vlans'
              '${cpuMember ? '\n\nAttention : le port CPU/bridge participe à cette entrée. Elle peut porter le VLAN de management ou du routage inter-VLAN.' : ''}',
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
    await widget.service.remove('/interface/bridge/vlan', id);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final data = visible;
    final dynamicCount = rows
        .where((e) => e['dynamic'] == 'yes' || e['dynamic'] == 'true')
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Bridge VLAN Table (${rows.length})'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une entrée VLAN'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Recherche',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('$dynamicCount dynamique(s)')),
                    FilterChip(
                      selected: showDynamic,
                      label: const Text('Afficher dynamiques'),
                      onSelected: (v) => setState(() => showDynamic = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: data.length,
                      itemBuilder: (_, i) {
                        final r = data[i];
                        final dynamic =
                            r['dynamic'] == 'yes' || r['dynamic'] == 'true';
                        final bridge = r['bridge'] ?? '';
                        final tagged = BridgeVlanValidator.splitMembers(
                          r['current-tagged'] ?? r['tagged'],
                        );
                        final untagged = BridgeVlanValidator.splitMembers(
                          r['current-untagged'] ?? r['untagged'],
                        );
                        final cpu =
                            tagged.contains(bridge) ||
                            untagged.contains(bridge);
                        return Card(
                          child: ListTile(
                            onTap: dynamic ? null : () => edit(r),
                            leading: Icon(
                              dynamic
                                  ? Icons.auto_awesome
                                  : cpu
                                  ? Icons.router_outlined
                                  : Icons.lan_outlined,
                            ),
                            title: Text(
                              '${bridge.isEmpty ? '—' : bridge} • VLAN ${r['vlan-ids'] ?? '—'}',
                            ),
                            subtitle: Text(
                              [
                                'Tagged ${tagged.isEmpty ? '—' : tagged.join(', ')}',
                                'Untagged ${untagged.isEmpty ? '—' : untagged.join(', ')}',
                                if (cpu) 'CPU/bridge membre',
                              ].join('\n'),
                            ),
                            trailing: dynamic
                                ? const Chip(label: Text('dynamique'))
                                : IconButton(
                                    onPressed: () => removeEntry(r),
                                    icon: const Icon(Icons.delete_outline),
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
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
