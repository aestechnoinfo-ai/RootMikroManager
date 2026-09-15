import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemHealthScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemHealthScreen({super.key, required this.service});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      rows = await widget.service.systemHealth();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Color colorFor(Map<String, String> row) {
    final name = (row['name'] ?? '').toLowerCase();
    final value = double.tryParse(row['value'] ?? '') ?? 0;
    if (name.contains('temperature')) {
      if (value >= 80) return Colors.red;
      if (value >= 65) return Colors.orange;
      return Colors.green;
    }
    if (name.contains('voltage')) {
      return value <= 0 ? Colors.orange : Colors.green;
    }
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Santé matériel'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Les capteurs ne sont peut-être pas disponibles sur ce modèle.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          )
        : rows.isEmpty
        ? const Center(
            child: Text('Aucun capteur de santé exposé par ce routeur.'),
          )
        : RefreshIndicator(
            onRefresh: load,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final row = rows[i];
                final color = colorFor(row);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(Icons.monitor_heart_outlined, color: color),
                    ),
                    title: Text(row['name'] ?? 'Capteur'),
                    subtitle: Text(row['type'] ?? ''),
                    trailing: Text(
                      '${row['value'] ?? '—'} ${row['type'] ?? ''}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
  );
}
