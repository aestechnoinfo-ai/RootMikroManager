import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RouterFilesScreen extends StatefulWidget {
  final RouterOsService service;
  const RouterFilesScreen({super.key, required this.service});

  @override
  State<RouterFilesScreen> createState() => _RouterFilesScreenState();
}

class _RouterFilesScreenState extends State<RouterFilesScreen> {
  List<Map<String, String>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await widget.service.files();
    if (mounted) setState(() => loading = false);
  }

  Future<void> remove(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le fichier ?'),
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
    );
    if (ok != true) return;
    await widget.service.removeFile(id);
    await load();
  }

  Future<void> restore(Map<String, String> row) async {
    final name = row['name'];
    if (name == null || !name.endsWith('.backup')) return;

    final password = TextEditingController();
    final confirm = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer le backup RouterOS ?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$name\n\n'
                'Cette opération remplace la configuration et provoque '
                'le redémarrage du MikroTik. Utilisez de préférence un '
                'backup créé avec la même version RouterOS.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe du backup (si chiffré)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirm,
                decoration: const InputDecoration(labelText: 'Tapez RESTAURER'),
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
              confirm.text.trim().toUpperCase() == 'RESTAURER',
            ),
            child: const Text('Restaurer et redémarrer'),
          ),
        ],
      ),
    );

    if (ok != true) {
      password.dispose();
      confirm.dispose();
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
          content: Text(
            'Commande de restauration envoyée. Le routeur peut redémarrer.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restauration: $e')));
    } finally {
      password.dispose();
      confirm.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fichiers RouterOS')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Cette vue gère les fichiers présents sur le routeur. '
                      'Le téléchargement binaire vers le téléphone n’est pas simulé : '
                      'il nécessite un transport de fichier dédié.',
                    ),
                  ),
                ),
                for (final row in rows)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        (row['name'] ?? '').endsWith('.backup')
                            ? Icons.backup_outlined
                            : Icons.insert_drive_file_outlined,
                      ),
                      title: Text(row['name'] ?? '—'),
                      subtitle: Text(
                        'Type: ${row['type'] ?? '—'} • '
                        'Taille: ${row['size'] ?? '—'} • '
                        '${row['creation-time'] ?? ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'restore') restore(row);
                          if (action == 'delete') remove(row);
                        },
                        itemBuilder: (_) => [
                          if ((row['name'] ?? '').endsWith('.backup'))
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
                  ),
              ],
            ),
          ),
  );
}
