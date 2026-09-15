import 'package:flutter/material.dart';

import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class VlanScreen extends StatefulWidget {
  final RouterOsService service;
  const VlanScreen({super.key, required this.service});

  @override
  State<VlanScreen> createState() => _VlanScreenState();
}

class _VlanScreenState extends State<VlanScreen> {
  final search = TextEditingController();
  bool loading = true;
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
    rows = await widget.service.vlanInterfaces();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.vlanEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> action(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final disabled = row['disabled'] == 'yes' || row['disabled'] == 'true';
    if (action == 'edit') return edit(row);
    if (action == 'toggle') {
      if (disabled) {
        await widget.service.enable('/interface/vlan', id);
      } else {
        await widget.service.disable('/interface/vlan', id);
      }
      return load();
    }
    if (action == 'delete') {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Supprimer ${row['name'] ?? 'ce VLAN'} ?'),
              content: const Text(
                'Si cette interface porte une adresse IP de management, du DHCP, du Hotspot ou du routage, la suppression peut couper des services.',
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
      await widget.service.remove('/interface/vlan', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = visible;
    final disabled = rows
        .where((e) => e['disabled'] == 'yes' || e['disabled'] == 'true')
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Interfaces VLAN (${rows.length})'),
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
                    label: const Text('Ajouter VLAN'),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(label: Text('$disabled désactivée(s)')),
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
                            leading: CircleAvatar(
                              child: Text(r['vlan-id'] ?? 'V'),
                            ),
                            title: Text(r['name'] ?? '—'),
                            subtitle: Text(
                              [
                                'Parent ${r['interface'] ?? '—'}',
                                'VLAN ${r['vlan-id'] ?? '—'}',
                                if ((r['mtu'] ?? '').isNotEmpty)
                                  'MTU ${r['mtu']}',
                                if (r['use-service-tag'] == 'yes') 'S-Tag',
                                if (off) 'désactivée',
                              ].join(' • '),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) => action(v, r),
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
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
