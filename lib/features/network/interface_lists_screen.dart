import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class InterfaceListsScreen extends StatefulWidget {
  final RouterOsService service;
  const InterfaceListsScreen({super.key, required this.service});
  @override
  State<InterfaceListsScreen> createState() => _State();
}

class _State extends State<InterfaceListsScreen> {
  static const builtIns = {'all', 'none', 'dynamic', 'static'};
  bool loading = true;
  List<Map<String, String>> lists = [], members = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.interfaceLists(),
      widget.service.interfaceListMembers(),
    ]);
    lists = x[0];
    members = x[1];
    if (mounted) setState(() => loading = false);
  }

  Future<void> editList([Map<String, String>? row]) async {
    final ok = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.interfaceListEdit,
      extra: OptionalRowPayload(row),
    );
    if (ok == true) await load();
  }

  Future<void> editMember([Map<String, String>? row]) async {
    final ok = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.interfaceListMemberEdit,
      extra: OptionalRowPayload(row),
    );
    if (ok == true) await load();
  }

  Future<void> deleteList(Map<String, String> row) async {
    final name = row['name'] ?? '', id = row['.id'];
    if (builtIns.contains(name) || id == null) return;
    final count = members.where((m) => m['list'] == name).length;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Suppression bloquée : $count membre(s) statique(s) utilisent encore $name.',
          ),
        ),
      );
      return;
    }
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Supprimer $name ?'),
            content: const Text(
              'Vérifiez aussi que cette liste n’est pas référencée dans firewall, Neighbor Discovery ou Bridge VLAN.',
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
      await widget.service.remove('/interface/list', id);
      await load();
    }
  }

  Future<void> deleteMember(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Retirer ce membre ?'),
            content: Text(
              '${row['interface'] ?? '—'} de ${row['list'] ?? '—'}',
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
    if (ok) {
      await widget.service.remove('/interface/list/member', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Interface Lists'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => editList(),
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle liste'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => editMember(),
                icon: const Icon(Icons.playlist_add),
                label: const Text('Ajouter un membre'),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'RouterOS possède quatre listes prédéfinies : all, none, dynamic et static. Elles sont protégées ici. '
                          'Ordre logique : include → exclude → membres statiques. Un bridge dans une liste ne représente pas automatiquement ses ports ; cela peut changer le comportement du Neighbor Discovery.',
                        ),
                      ),
                    ),
                    for (final r in lists)
                      Card(
                        child: ExpansionTile(
                          leading: Icon(
                            builtIns.contains(r['name'])
                                ? Icons.lock_outline
                                : Icons.list_alt,
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            'include ${r['include'] ?? '—'} • exclude ${r['exclude'] ?? '—'}',
                          ),
                          trailing: builtIns.contains(r['name'])
                              ? null
                              : PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') editList(r);
                                    if (v == 'delete') deleteList(r);
                                  },
                                  itemBuilder: (_) => const [
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
                          children: [
                            for (final m in members.where(
                              (m) => m['list'] == r['name'],
                            ))
                              ListTile(
                                leading: const Icon(
                                  Icons.settings_input_component_outlined,
                                ),
                                title: Text(m['interface'] ?? '—'),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') editMember(m);
                                    if (v == 'delete') deleteMember(m);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Modifier'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Retirer'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
