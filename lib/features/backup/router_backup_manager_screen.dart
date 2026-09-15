import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RouterBackupManagerScreen extends StatefulWidget {
  final RouterOsService service;

  const RouterBackupManagerScreen({super.key, required this.service});

  @override
  State<RouterBackupManagerScreen> createState() =>
      _RouterBackupManagerScreenState();
}

class _RouterBackupManagerScreenState extends State<RouterBackupManagerScreen> {
  final name = TextEditingController();
  final password = TextEditingController();
  bool encrypt = false;
  bool createRsc = true;
  bool busy = false;
  String status = '';

  @override
  void initState() {
    super.initState();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    name.text = 'rootmikromanager_$stamp';
  }

  Future<void> create() async {
    if (busy || name.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      status = '';
    });

    try {
      await widget.service.createRouterBackupAdvanced(
        name: name.text.trim(),
        password: encrypt ? password.text : '',
      );
      if (createRsc) {
        await widget.service.exportRouterConfig(name.text.trim());
      }
      status = createRsc
          ? 'Backup .backup et export .rsc créés sur le routeur.'
          : 'Backup .backup créé sur le routeur.';
    } catch (e) {
      status = 'Erreur : $e';
    }

    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Créer un backup RouterOS')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(
            labelText: 'Nom',
            suffixText: '.backup',
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Protéger le backup par mot de passe'),
          value: encrypt,
          onChanged: (v) => setState(() => encrypt = v),
        ),
        if (encrypt)
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe du backup',
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Créer aussi un export texte .rsc'),
          value: createRsc,
          onChanged: (v) => setState(() => createRsc = v),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: busy ? null : create,
          icon: const Icon(Icons.backup_outlined),
          label: Text(busy ? 'Création…' : 'Créer'),
        ),
        if (status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(status),
            ),
          ),
        ],
      ],
    ),
  );

  @override
  void dispose() {
    name.dispose();
    password.dispose();
    super.dispose();
  }
}
