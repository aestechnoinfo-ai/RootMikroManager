import 'package:flutter/material.dart';

import 'app_backup_service.dart';

class AppBackupScreen extends StatefulWidget {
  const AppBackupScreen({super.key});

  @override
  State<AppBackupScreen> createState() => _AppBackupScreenState();
}

class _AppBackupScreenState extends State<AppBackupScreen> {
  final service = AppBackupService();
  bool loading = true;
  bool busy = false;
  List<AppBackupFile> backups = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    backups = await service.list();
    if (mounted) setState(() => loading = false);
  }

  Future<void> create() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await service.create();
      await load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sauvegarde JSON créée.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> restore(AppBackupFile backup) async {
    bool replace = false;
    final accepted =
        await showDialog<bool>(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (context, setLocalState) => AlertDialog(
              title: const Text('Restaurer cette sauvegarde ?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(backup.name),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remplacer les données existantes'),
                    subtitle: const Text(
                      'Sinon les données sont fusionnées lorsque possible.',
                    ),
                    value: replace,
                    onChanged: (v) => setLocalState(() => replace = v ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Restaurer'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!accepted) return;

    setState(() => busy = true);
    try {
      await service.restore(backup, replaceExisting: replace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sauvegarde restaurée.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete(AppBackupFile backup) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer la sauvegarde ?'),
            content: Text(backup.name),
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

    await service.delete(backup);
    await load();
  }

  String size(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sauvegardes RootMikroManager'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : create,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Créer une sauvegarde JSON'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : backups.isEmpty
              ? const Center(child: Text('Aucune sauvegarde locale.'))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: backups.length,
                    itemBuilder: (_, i) {
                      final backup = backups[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(backup.name),
                          subtitle: Text(
                            '${size(backup.size)} • '
                            '${backup.modifiedAt.toLocal()}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'restore') restore(backup);
                              if (v == 'delete') delete(backup);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'restore',
                                child: Text('Restaurer'),
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
}
