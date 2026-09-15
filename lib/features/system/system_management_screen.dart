import 'package:flutter/material.dart';

import '../../core/routeros/router_session.dart';

class SystemManagementScreen extends StatefulWidget {
  final String title;
  final String path;

  const SystemManagementScreen({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  State<SystemManagementScreen> createState() => _SystemManagementScreenState();
}

class _SystemManagementScreenState extends State<SystemManagementScreen> {
  List<Map<String, String>> rows = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      rows = await RouterSession.instance.service.client.print(widget.path);
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([Map<String, String>? row]) async {
    final name = TextEditingController(text: row?['name'] ?? '');
    final source = TextEditingController(
      text: row?['source'] ?? row?['on-event'] ?? '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          row == null ? 'Créer ${widget.title}' : 'Modifier ${widget.title}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: source,
                minLines: 4,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: widget.path.contains('scheduler')
                      ? 'On Event'
                      : 'Source',
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
    );

    if (ok == true) {
      final key = widget.path.contains('scheduler') ? 'on-event' : 'source';
      final values = <String, String>{
        'name': name.text.trim(),
        key: source.text,
      };

      if (row == null) {
        await RouterSession.instance.service.add(widget.path, values);
      } else {
        await RouterSession.instance.service.set(
          widget.path,
          row['.id']!,
          values,
        );
      }
      await load();
    }

    name.dispose();
    source.dispose();
  }

  Future<void> removeRow(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text('Supprimer « ${row['name'] ?? 'Sans nom'} » ?'),
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

    if (!confirmed) return;

    await RouterSession.instance.service.remove(widget.path, id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          tooltip: 'Ajouter',
          onPressed: loading ? null : () => edit(),
          icon: const Icon(Icons.add),
        ),
        IconButton(
          tooltip: 'Actualiser',
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(error!),
            ),
          )
        : rows.isEmpty
        ? Center(
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: Text('Ajouter ${widget.title}'),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return Card(
                child: ListTile(
                  title: Text(row['name'] ?? 'Sans nom'),
                  subtitle: Text(
                    row['source'] ?? row['on-event'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => edit(row),
                  trailing: IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => removeRow(row),
                  ),
                ),
              );
            },
          ),
  );
}
