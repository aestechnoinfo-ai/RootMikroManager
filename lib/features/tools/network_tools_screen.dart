import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class NetworkToolsScreen extends StatefulWidget {
  final RouterOsService service;
  const NetworkToolsScreen({super.key, required this.service});
  @override
  State<NetworkToolsScreen> createState() => _NetworkToolsScreenState();
}

class _NetworkToolsScreenState extends State<NetworkToolsScreen> {
  final target = TextEditingController(text: '8.8.8.8');
  final count = TextEditingController(text: '4');
  bool loading = false;
  String output = '';

  Future<void> runPing() async {
    setState(() {
      loading = true;
      output = '';
    });
    try {
      final rows = await widget.service.ping(
        target.text.trim(),
        count: int.tryParse(count.text) ?? 4,
      );
      output = rows
          .map((e) => e.entries.map((x) => '${x.key}=${x.value}').join(' | '))
          .join('\n');
    } catch (e) {
      output = 'Erreur : $e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> runTraceroute() async {
    setState(() {
      loading = true;
      output = '';
    });
    try {
      final rows = await widget.service.traceroute(target.text.trim());
      output = rows
          .map((e) => e.entries.map((x) => '${x.key}=${x.value}').join(' | '))
          .join('\n');
    } catch (e) {
      output = 'Erreur : $e';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Outils réseau')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: target,
          decoration: const InputDecoration(labelText: 'Adresse IP ou domaine'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: count,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nombre de paquets Ping',
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: loading ? null : runPing,
              icon: const Icon(Icons.network_ping),
              label: const Text('Ping'),
            ),
            OutlinedButton.icon(
              onPressed: loading ? null : runTraceroute,
              icon: const Icon(Icons.route),
              label: const Text('Traceroute'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (loading) const Center(child: CircularProgressIndicator()),
        if (output.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(output),
            ),
          ),
      ],
    ),
  );

  @override
  void dispose() {
    target.dispose();
    count.dispose();
    super.dispose();
  }
}
