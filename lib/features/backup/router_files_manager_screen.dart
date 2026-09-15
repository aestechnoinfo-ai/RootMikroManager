import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RouterFilesManagerScreen extends StatefulWidget {
  final RouterOsService service;

  const RouterFilesManagerScreen({super.key, required this.service});

  @override
  State<RouterFilesManagerScreen> createState() =>
      _RouterFilesManagerScreenState();
}

class _RouterFilesManagerScreenState extends State<RouterFilesManagerScreen> {
  final search = TextEditingController();
  String filter = 'all';
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
    rows = await widget.service.files();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((row) {
      final name = (row['name'] ?? '').toLowerCase();
      if (q.isNotEmpty && !name.contains(q)) return false;
      if (filter == 'backup') return name.endsWith('.backup');
      if (filter == 'rsc') return name.endsWith('.rsc');
      return true;
    }).toList();
  }

  Future<void> restore(Map<String, String> row) async {
    final name = row['name'] ?? '';
    if (!name.endsWith('.backup')) return;

    final password = TextEditingController();
    final confirmation = TextEditingController();

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Restaurer le backup ?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name),
                  const SizedBox(height: 10),
                  const Text(
                    'Cette opération remplace la configuration du routeur '
                    'et provoque normalement un redémarrage.',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe du backup si nécessaire',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmation,
                    decoration: const InputDecoration(
                      labelText: 'Tapez RESTAURER',
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
                onPressed: () => Navigator.pop(
                  context,
                  confirmation.text.trim().toUpperCase() == 'RESTAURER',
                ),
                child: const Text('Restaurer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) {
      password.dispose();
      confirmation.dispose();
      return;
    }

    try {
      await widget.service.restoreRouterBackup(
        name: name,
        password: password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande de restauration envoyée au routeur.'),
        ),
      );
    } finally {
      password.dispose();
      confirmation.dispose();
    }
  }

  Future<void> delete(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer ce fichier ?'),
            content: Text(row['name'] ?? 'Fichier RouterOS'),
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

    await widget.service.removeFile(id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Fichiers RouterOS'),
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
              labelText: 'Rechercher un fichier',
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('Tous')),
              ButtonSegment(value: 'backup', label: Text('Backups')),
              ButtonSegment(value: 'rsc', label: Text('Exports RSC')),
            ],
            selected: {filter},
            onSelectionChanged: (v) => setState(() => filter = v.first),
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
                      final row = visible[i];
                      final name = row['name'] ?? '—';
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            name.endsWith('.backup')
                                ? Icons.backup_outlined
                                : name.endsWith('.rsc')
                                ? Icons.code_outlined
                                : Icons.insert_drive_file_outlined,
                          ),
                          title: Text(name),
                          subtitle: Text(
                            [
                              if ((row['type'] ?? '').isNotEmpty)
                                'Type ${row['type']}',
                              if ((row['size'] ?? '').isNotEmpty)
                                'Taille ${row['size']}',
                              if ((row['creation-time'] ?? '').isNotEmpty)
                                row['creation-time']!,
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'restore') restore(row);
                              if (v == 'delete') delete(row);
                            },
                            itemBuilder: (_) => [
                              if (name.endsWith('.backup'))
                                const PopupMenuItem(
                                  value: 'restore',
                                  child: Text('Restaurer'),
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
