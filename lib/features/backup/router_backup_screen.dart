import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RouterBackupScreen extends StatefulWidget {
  final RouterOsService service;
  const RouterBackupScreen({super.key, required this.service});
  @override
  State<RouterBackupScreen> createState() => _RouterBackupScreenState();
}

class _RouterBackupScreenState extends State<RouterBackupScreen> {
  final name = TextEditingController(text: 'rootmikromanager_backup');
  bool loading = false;
  String status = '';
  Future<void> backup() async {
    setState(() => loading = true);
    try {
      await widget.service.createRouterBackup(name.text);
      await widget.service.exportRouterConfig(name.text);
      status = 'Commandes de backup et export envoyées au routeur.';
    } catch (e) {
      status = 'Erreur: $e';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Backup RouterOS')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nom du backup'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : backup,
            icon: const Icon(Icons.save_alt),
            label: const Text('Créer Backup + Export'),
          ),
          const SizedBox(height: 20),
          Text(status),
          const SizedBox(height: 12),
          const Text(
            'Le backup est créé sur le stockage du routeur. RootMikroManager envoie aussi une commande d’export .rsc pour la configuration texte.',
          ),
        ],
      ),
    ),
  );
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}
