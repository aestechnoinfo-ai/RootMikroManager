import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/export/user_selected_export_service.dart';

class LoggingExportScreen extends StatefulWidget {
  final RouterOsService service;
  const LoggingExportScreen({super.key, required this.service});
  @override
  State<LoggingExportScreen> createState() => _S();
}

class _S extends State<LoggingExportScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  String format = 'csv';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await widget.service.logs();
    if (mounted) setState(() => loading = false);
  }

  String esc(String v) => '"${v.replaceAll('"', '""')}"';
  String data() {
    if (format == 'text')
      return rows
          .map(
            (r) =>
                '[${r['time'] ?? ''}] ${r['topics'] ?? ''} ${r['message'] ?? ''}',
          )
          .join('\\n');
    return 'time,topics,buffer,message\\n${rows.map((r) => [esc(r['time'] ?? ''), esc(r['topics'] ?? ''), esc(r['buffer'] ?? ''), esc(r['message'] ?? '')].join(',')).join('\\n')}';
  }

  Future<void> copy() async {
    await Clipboard.setData(ClipboardData(text: data()));
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export copié.')));
  }

  Future<void> save() async {
    final location = await const UserSelectedExportService().saveText(
      suggestedName:
          'routeros_logs_${DateTime.now().millisecondsSinceEpoch}.$format',
      mimeType: format == 'csv' ? 'text/csv' : 'text/plain',
      content: data(),
    );
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            location == null
                ? 'Export annulé.'
                : 'Export enregistré dans l’emplacement choisi.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Export des logs')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              DropdownButtonFormField<String>(isExpanded: true, 
                value: format,
                decoration: const InputDecoration(labelText: 'Format'),
                items: const ['csv', 'text']
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => format = v ?? 'csv'),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text('${rows.length} entrée(s)'),
                  subtitle: const Text(
                    'Export du contenu actuellement retourné par /log.',
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Enregistrer où je veux'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: copy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copier l’export'),
              ),
              const SizedBox(height: 12),
              SelectableText(data(), maxLines: 24),
            ],
          ),
  );
}
