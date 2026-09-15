import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RouterExportScreen extends StatefulWidget {
  final RouterOsService service;
  const RouterExportScreen({super.key, required this.service});

  @override
  State<RouterExportScreen> createState() => _RouterExportScreenState();
}

class _RouterExportScreenState extends State<RouterExportScreen> {
  final name = TextEditingController();
  bool busy = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    name.text =
        'rootmikromanager_export_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> export() async {
    if (busy || name.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      message = '';
    });

    try {
      await widget.service.exportRouterConfig(name.text.trim());
      message = 'Export créé sur le routeur : ${name.text.trim()}.rsc';
    } catch (e) {
      message = 'Erreur : $e';
    }

    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Exporter RouterOS')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'L’export .rsc est un script texte RouterOS. Il est '
              'différent d’un backup binaire .backup.',
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: name,
          decoration: const InputDecoration(
            labelText: 'Nom de l’export',
            suffixText: '.rsc',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : export,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Créer l’export'),
        ),
        if (message.isNotEmpty) ...[const SizedBox(height: 16), Text(message)],
      ],
    ),
  );

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}
