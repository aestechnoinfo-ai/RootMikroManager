import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<Map<String, Object?>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await AppDatabase.instance.logs();
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer le journal ?'),
        content: const Text(
          'Cette action supprime le journal '
          'local des activités.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AppDatabase.instance.clearLogs();
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal d’audit'),
        actions: [
          IconButton(
            tooltip: 'Effacer',
            onPressed: clear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    '${rows.length} événement(s)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final row in rows)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(row['action']?.toString() ?? 'activité'),
                        subtitle: Text(_details(row['data'])),
                        trailing: Text(
                          _shortDate(row['created_at']?.toString()),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _details(Object? raw) {
    final text = raw?.toString() ?? '';
    if (text.isEmpty) return '';

    try {
      final data = jsonDecode(text);
      if (data is Map) {
        return data.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' • ');
      }
    } catch (_) {}

    return text;
  }

  String _shortDate(String? value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value);
    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}\n'
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
