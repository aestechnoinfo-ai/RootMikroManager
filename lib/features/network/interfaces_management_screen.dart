import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class InterfacesManagementScreen extends StatefulWidget {
  final RouterOsService service;
  const InterfacesManagementScreen({super.key, required this.service});

  @override
  State<InterfacesManagementScreen> createState() =>
      _InterfacesManagementScreenState();
}

class _InterfacesManagementScreenState
    extends State<InterfacesManagementScreen> {
  final search = TextEditingController();
  String type = 'all';
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
    rows = await widget.service.interfaces();
    if (mounted) setState(() => loading = false);
  }

  List<String> get types {
    final values =
        rows
            .map((e) => (e['type'] ?? '').trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['all', ...values];
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) {
      if (type != 'all' && r['type'] != type) return false;
      if (q.isNotEmpty && !r.values.any((v) => v.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> toggle(Map<String, String> row) async {
    final dynamic = row['dynamic'] == 'yes' || row['dynamic'] == 'true';
    if (dynamic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Interface dynamique : modifiez le service qui la crée.',
          ),
        ),
      );
      return;
    }
    final id = row['.id'];
    if (id == null) return;
    final disabled = row['disabled'] == 'yes' || row['disabled'] == 'true';
    if (disabled) {
      await widget.service.enable('/interface', id);
    } else {
      await widget.service.disable('/interface', id);
    }
    await load();
  }

  Future<void> detail(Map<String, String> row) async {
    await AppRouter.pushNamed(
      context,
      AppRoutes.interfaceDetail,
      extra: RequiredRowPayload(row),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Interfaces (${rows.length})'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    'Running ${rows.where((r) => r['running'] == 'yes' || r['running'] == 'true').length}',
                  ),
                  Text(
                    'Désactivées ${rows.where((r) => r['disabled'] == 'yes' || r['disabled'] == 'true').length}',
                  ),
                  Text(
                    'Dynamiques ${rows.where((r) => r['dynamic'] == 'yes' || r['dynamic'] == 'true').length}',
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, c) {
              final searchField = TextField(
                controller: search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Nom, type, MAC, commentaire…',
                ),
              );
              final typeField = DropdownButtonFormField<String>(
                value: types.contains(type) ? type : 'all',
                decoration: const InputDecoration(labelText: 'Type'),
                items: types
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e == 'all' ? 'Tous' : e),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => type = v ?? 'all'),
              );

              if (c.maxWidth < 650) {
                return Column(
                  children: [searchField, const SizedBox(height: 8), typeField],
                );
              }
              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  Expanded(child: typeField),
                ],
              );
            },
          ),
        ),
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
                          r['disabled'] == 'yes' || r['disabled'] == 'true';
                      final running =
                          r['running'] == 'yes' || r['running'] == 'true';
                      final dynamic =
                          r['dynamic'] == 'yes' || r['dynamic'] == 'true';
                      return Card(
                        child: ListTile(
                          onTap: () => detail(r),
                          leading: CircleAvatar(
                            child: Icon(
                              disabled
                                  ? Icons.pause
                                  : running
                                  ? Icons.link
                                  : Icons.link_off,
                            ),
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              if ((r['type'] ?? '').isNotEmpty) r['type']!,
                              if ((r['mac-address'] ?? '').isNotEmpty)
                                'MAC ${r['mac-address']}',
                              if ((r['mtu'] ?? '').isNotEmpty)
                                'MTU ${r['mtu']}',
                              if ((r['comment'] ?? '').isNotEmpty)
                                r['comment']!,
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'toggle') toggle(r);
                              if (v == 'detail') detail(r);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'detail',
                                child: Text('Détails'),
                              ),
                              if (!dynamic)
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(
                                    disabled ? 'Activer' : 'Désactiver',
                                  ),
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
