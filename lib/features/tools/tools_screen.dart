import 'package:flutter/material.dart';
import '../../core/routeros/router_session.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});
  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final host = TextEditingController(text: '8.8.8.8');
  String result = '';
  bool loading = false;
  Future<void> ping() async {
    setState(() => loading = true);
    try {
      final r = await RouterSession.instance.service.ping(host.text.trim());
      setState(
        () => result = r
            .expand((row) => row.entries)
            .map((e) => '${e.key}: ${e.value}')
            .join('\n'),
      );
    } catch (e) {
      setState(() => result = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Outils réseau')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: host,
            decoration: const InputDecoration(
              labelText: 'Hôte ou adresse IP',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : ping,
              icon: const Icon(Icons.network_ping),
              label: Text(loading ? 'Ping...' : 'Lancer Ping'),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                result.isEmpty ? 'Le résultat apparaîtra ici.' : result,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
