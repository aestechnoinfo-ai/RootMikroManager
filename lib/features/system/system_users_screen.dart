import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemUsersScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemUsersScreen({super.key, required this.service});

  @override
  State<SystemUsersScreen> createState() => _SystemUsersScreenState();
}

class _SystemUsersScreenState extends State<SystemUsersScreen> {
  final search = TextEditingController();
  bool loading = true;
  List<Map<String, String>> rows = [];
  List<String> groups = [];

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final values = await Future.wait([
      widget.service.systemUsers(),
      widget.service.systemUserGroups(),
    ]);
    rows = values[0];
    groups =
        values[1]
            .map((e) => (e['name'] ?? '').trim())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
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
    final name = TextEditingController(text: row?['name'] ?? '');
    final password = TextEditingController();
    final address = TextEditingController(text: row?['address'] ?? '');
    final comment = TextEditingController(text: row?['comment'] ?? '');
    String group = row?['group'] ?? (groups.isEmpty ? 'full' : groups.first);
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (context, local) => AlertDialog(
              title: Text(
                row == null ? 'Ajouter utilisateur' : 'Modifier utilisateur',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        helperText: 'Laisser vide pour ne pas le changer',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(isExpanded: true, 
                      value: groups.contains(group)
                          ? group
                          : groups.isEmpty
                          ? null
                          : groups.first,
                      decoration: const InputDecoration(labelText: 'Groupe'),
                      items: groups
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => local(() => group = v ?? group),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: address,
                      decoration: const InputDecoration(
                        labelText: 'Adresse autorisée',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: comment,
                      decoration: const InputDecoration(
                        labelText: 'Commentaire',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!ok || name.text.trim().isEmpty) return;

    final values = <String, String>{
      'name': name.text.trim(),
      if (group.isNotEmpty) 'group': group,
      if (password.text.isNotEmpty) 'password': password.text,
      if (address.text.trim().isNotEmpty) 'address': address.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    final id = row?['.id'];
    if (id == null) {
      await widget.service.add('/user', values);
    } else {
      await widget.service.set('/user', id, values);
    }
    await load();
  }

  Future<void> remove(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    await widget.service.remove('/user', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Utilisateurs RouterOS'),
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
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Ajouter un utilisateur'),
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
                      return Card(
                        child: ListTile(
                          onTap: () => editor(r),
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'Groupe ${r['group'] ?? '—'}',
                              if ((r['address'] ?? '').isNotEmpty)
                                'Adresse ${r['address']}',
                              if ((r['last-logged-in'] ?? '').isNotEmpty)
                                'Dernière connexion ${r['last-logged-in']}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') editor(r);
                              if (v == 'delete') remove(r);
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
