import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VoucherBatchCleanupScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherBatchCleanupScreen({super.key, required this.service});
  @override
  State<VoucherBatchCleanupScreen> createState() => _S();
}

class _S extends State<VoucherBatchCleanupScreen> {
  final comment = TextEditingController();
  bool running = false;
  String result = '';
  Future<void> removeUnused() async {
    final value = comment.text.trim();
    if (value.isEmpty) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer les tickets inutilisés ?'),
            content: Text(
              'Seuls les utilisateurs dont le commentaire correspond exactement à « $value » et dont uptime=00:00:00 seront supprimés.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    setState(() => running = true);
    try {
      final n = await widget.service.removeUnusedHotspotUsersByComment(value);
      result = '$n ticket(s) inutilisé(s) supprimé(s).';
    } catch (e) {
      result = '$e';
    }
    if (mounted) setState(() => running = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Nettoyage d’un lot de vouchers')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Cette action vise un lot précis par son commentaire. Elle ne touche pas aux profils Hotspot.',
            ),
          ),
        ),
        TextField(
          controller: comment,
          decoration: const InputDecoration(
            labelText: 'Commentaire exact du lot',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: running ? null : removeUnused,
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Supprimer les tickets inutilisés'),
        ),
        if (result.isNotEmpty) Card(child: ListTile(title: Text(result))),
      ],
    ),
  );
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }
}
