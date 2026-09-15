import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class DnsDiagnosticsScreen extends StatefulWidget {
  final RouterOsService service;
  const DnsDiagnosticsScreen({super.key, required this.service});

  @override
  State<DnsDiagnosticsScreen> createState() => _DnsDiagnosticsScreenState();
}

class _DnsDiagnosticsScreenState extends State<DnsDiagnosticsScreen> {
  final name = TextEditingController(text: 'example.com');
  bool loading = false;
  List<Map<String, String>> results = [];

  Future<void> resolve() async {
    if (name.text.trim().isEmpty || loading) return;
    setState(() {
      loading = true;
      results = [];
    });
    try {
      results = await widget.service.resolveDns(name.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnostic DNS')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(
            labelText: 'Nom à résoudre',
            prefixIcon: Icon(Icons.language),
          ),
          onSubmitted: (_) => resolve(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: loading ? null : resolve,
          icon: const Icon(Icons.search),
          label: const Text('Résoudre depuis le routeur'),
        ),
        const SizedBox(height: 16),
        if (loading) const Center(child: CircularProgressIndicator()),
        for (final r in results)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                r.entries
                    .where((e) => e.value.isNotEmpty)
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n'),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}
