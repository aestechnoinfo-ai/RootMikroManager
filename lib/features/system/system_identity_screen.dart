import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemIdentityScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemIdentityScreen({super.key, required this.service});

  @override
  State<SystemIdentityScreen> createState() => _SystemIdentityScreenState();
}

class _SystemIdentityScreenState extends State<SystemIdentityScreen> {
  final name = TextEditingController();
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final row = await widget.service.identity();
    name.text = row['name'] ?? '';
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    try {
      await widget.service.setSystemIdentity(name.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Identité mise à jour.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Identité du routeur')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom du routeur'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
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
