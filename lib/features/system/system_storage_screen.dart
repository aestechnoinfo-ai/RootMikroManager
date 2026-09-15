import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemStorageScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemStorageScreen({super.key, required this.service});

  @override
  State<SystemStorageScreen> createState() => _SystemStorageScreenState();
}

class _SystemStorageScreenState extends State<SystemStorageScreen> {
  bool loading = true;
  List<Map<String, String>> files = [];
  Map<String, String> resource = {};
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    resource = await widget.service.resource();
    files = await widget.service.files();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return files;
    return files
        .where((r) => (r['name'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  Future<void> remove(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer le fichier ?'),
            content: Text(row['name'] ?? ''),
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
      title: const Text('Stockage / fichiers'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: Text('Libre : ${resource['free-hdd-space'] ?? '—'}'),
                    subtitle: Text(
                      'Total : ${resource['total-hdd-space'] ?? '—'}',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Rechercher un fichier',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final row = visible[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(row['name'] ?? 'Fichier'),
                        subtitle: Text(
                          [
                            if ((row['type'] ?? '').isNotEmpty) row['type']!,
                            if ((row['size'] ?? '').isNotEmpty)
                              'Taille: ${row['size']}',
                            if ((row['creation-time'] ?? '').isNotEmpty)
                              row['creation-time']!,
                          ].join(' • '),
                        ),
                        trailing: IconButton(
                          tooltip: 'Supprimer',
                          onPressed: () => remove(row),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    );
                  },
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
