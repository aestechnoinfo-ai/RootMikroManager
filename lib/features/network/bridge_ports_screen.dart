import 'package:flutter/material.dart';

import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class BridgePortsScreen extends StatefulWidget {
  final RouterOsService service;
  const BridgePortsScreen({super.key, required this.service});

  @override
  State<BridgePortsScreen> createState() => _BridgePortsScreenState();
}

class _BridgePortsScreenState extends State<BridgePortsScreen> {
  final search = TextEditingController();
  bool loading = true;
  bool onlyHardware = false;
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
    rows = await widget.service.bridgePortsAdvanced();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) {
      if (onlyHardware && r['hw'] != 'yes') return false;
      if (q.isNotEmpty && !r.values.any((v) => v.toLowerCase().contains(q)))
        return false;
      return true;
    }).toList();
  }

  Future<void> edit(Map<String, String> row) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.bridgePortEdit,
      extra: RequiredRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> toggle(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final disabled = row['disabled'] == 'yes' || row['disabled'] == 'true';
    await widget.service.set('/interface/bridge/port', id, {
      'disabled': disabled ? 'no' : 'yes',
    });
    await load();
  }

  Future<void> remove(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Retirer ce port du bridge ?'),
            content: Text(
              '${row['interface'] ?? 'Ce port'} sera retiré de ${row['bridge'] ?? 'son bridge'}. '
              'Un trunk ou port de management mal retiré peut couper la connexion.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Retirer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await widget.service.remove('/interface/bridge/port', id);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final data = visible;
    final hw = rows.where((e) => e['hw'] == 'yes').length;
    final disabled = rows
        .where((e) => e['disabled'] == 'yes' || e['disabled'] == 'true')
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Bridge Ports (${rows.length})'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('$hw HW offload')),
                Chip(label: Text('$disabled désactivé(s)')),
                FilterChip(
                  selected: onlyHardware,
                  label: const Text('HW seulement'),
                  onSelected: (v) => setState(() => onlyHardware = v),
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
                        final off =
                            r['disabled'] == 'yes' || r['disabled'] == 'true';
                        return Card(
                          child: ListTile(
                            onTap: () => edit(r),
                            leading: Icon(
                              r['hw'] == 'yes'
                                  ? Icons.memory
                                  : Icons.settings_ethernet,
                            ),
                            title: Text(r['interface'] ?? '—'),
                            subtitle: Text(
                              [
                                r['bridge'] ?? '—',
                                'PVID ${r['pvid'] ?? '1'}',
                                r['frame-types'] ?? 'admit-all',
                                if (r['ingress-filtering'] == 'yes') 'ingress',
                                if (off) 'désactivé',
                              ].join(' • '),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') edit(r);
                                if (v == 'toggle') toggle(r);
                                if (v == 'delete') remove(r);
                              },
                              itemBuilder: (_) => [
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
                                  child: Text('Retirer du bridge'),
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
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
