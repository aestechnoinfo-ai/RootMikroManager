import 'package:flutter/material.dart';
import '../../core/routeros/router_session.dart';

class CrudRouterScreen extends StatefulWidget {
  final String title;
  final String path;
  final Future<List<Map<String, String>>> Function() loader;

  const CrudRouterScreen({
    super.key,
    required this.title,
    required this.path,
    required this.loader,
  });

  @override
  State<CrudRouterScreen> createState() => _CrudRouterScreenState();
}

class _CrudRouterScreenState extends State<CrudRouterScreen> {
  List<Map<String, String>> rows = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await widget.loader();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> addItem() async {
    final service = RouterSession.instance.service;
    final fields = _fieldsForPath(widget.path);
    final controllers = {
      for (final field in fields) field: TextEditingController(),
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter — ${widget.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in fields)
                TextField(
                  controller: controllers[field],
                  decoration: InputDecoration(labelText: _label(field)),
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
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final values = <String, String>{
        for (final entry in controllers.entries)
          if (entry.value.text.trim().isNotEmpty)
            entry.key: entry.value.text.trim(),
      };
      if (values.isNotEmpty) {
        await service.add(widget.path, values);
        await load();
      }
    }
  }

  Future<void> remove(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    await RouterSession.instance.service.remove(widget.path, id);
    await load();
  }

  List<String> _fieldsForPath(String path) {
    if (path == '/ip/dhcp-server/lease')
      return ['address', 'mac-address', 'comment'];
    if (path == '/ip/dns/static') return ['name', 'address', 'comment'];
    if (path == '/queue/simple')
      return ['name', 'target', 'max-limit', 'comment'];
    return ['name', 'comment'];
  }

  String _label(String field) {
    const labels = {
      'address': 'Adresse',
      'mac-address': 'Adresse MAC',
      'name': 'Nom',
      'target': 'Cible',
      'max-limit': 'Max limit',
      'comment': 'Commentaire',
    };
    return labels[field] ?? field;
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    if (error != null)
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Text(error!)),
      );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${rows.length} élément(s)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final row in rows)
              Card(
                child: ListTile(
                  title: Text(
                    row['name'] ??
                        row['address'] ??
                        row['target'] ??
                        row['mac-address'] ??
                        '—',
                  ),
                  subtitle: Text(
                    ['address', 'mac-address', 'target', 'max-limit', 'comment']
                        .where((key) => (row[key] ?? '').isNotEmpty)
                        .map((key) => '$key: ${row[key]}')
                        .join(' • '),
                  ),
                  trailing: IconButton(
                    tooltip: 'Supprimer',
                    onPressed: () => remove(row),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
