import 'package:flutter/material.dart';
import '../../core/export/user_selected_export_service.dart';
import '../../core/routeros/routeros_service.dart';

class PppExportScreen extends StatefulWidget {
  final RouterOsService service;
  const PppExportScreen({super.key, required this.service});
  @override
  State<PppExportScreen> createState() => _S();
}

class _S extends State<PppExportScreen> {
  bool busy = false, includePasswords = false;
  String message = '';
  String q(String v) => '"${v.replaceAll('"', '""')}"';
  Future<void> export() async {
    if (includePasswords) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Exporter les mots de passe PPP ?'),
              content: const Text(
                'Le CSV sera stocké en clair. Toute personne ayant accès au fichier pourra lire les identifiants PPP.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          ) ??
          false;
      if (!ok) return;
    }
    setState(() => busy = true);
    try {
      final rows = await widget.service.pppSecrets();
      final fields = <String>[
        'name',
        if (includePasswords) 'password',
        'service',
        'profile',
        'local-address',
        'remote-address',
        'caller-id',
        'routes',
        'disabled',
        'comment',
      ];
      final b = StringBuffer()..writeln(fields.join(','));
      for (final r in rows)
        b.writeln(fields.map((f) => q(r[f] ?? '')).join(','));
      final location = await const UserSelectedExportService().saveText(
        suggestedName:
            'ppp_${includePasswords ? 'sensitive_' : 'safe_'}${DateTime.now().millisecondsSinceEpoch}.csv',
        mimeType: 'text/csv',
        content: b.toString(),
      );
      message = location == null
          ? 'Export annulé.'
          : 'CSV enregistré dans l’emplacement choisi.';
    } catch (e) {
      message = 'Erreur : $e';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Exporter PPP')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Par défaut, RootMikroManager exclut les mots de passe du CSV PPP. Activez explicitement l’option sensible uniquement si nécessaire.',
            ),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Inclure les mots de passe'),
          subtitle: const Text('Export sensible en clair'),
          value: includePasswords,
          onChanged: busy ? null : (v) => setState(() => includePasswords = v),
        ),
        FilledButton.icon(
          onPressed: busy ? null : export,
          icon: const Icon(Icons.file_download_outlined),
          label: Text(busy ? 'Export…' : 'Créer le CSV'),
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 14),
          SelectableText(message),
        ],
      ],
    ),
  );
}
