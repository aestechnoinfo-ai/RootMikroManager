import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';

import '../../core/database/app_database.dart';
import '../../core/export/user_selected_export_service.dart';
import '../../core/routeros/router_session.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool busy = false;
  String? message;
  String? localPath;

  Future<void> exportAppJson() async {
    setState(() {
      busy = true;
      message = null;
    });

    try {
      final data = await AppDatabase.instance.exportJson();
      localPath = await const UserSelectedExportService().saveText(
        suggestedName:
            'RootMikroManager_${DateTime.now().millisecondsSinceEpoch}.json',
        mimeType: 'application/json',
        content: const JsonEncoder.withIndent(' ').convert(data),
      );
      message = localPath == null
          ? 'Export annulé.'
          : 'Sauvegarde JSON créée dans l’emplacement choisi.';
    } catch (e) {
      message = '$e';
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> importJsonDialog() async {
    final controller = TextEditingController();
    bool replace = false;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('Restaurer une sauvegarde JSON'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      minLines: 8,
                      maxLines: 18,
                      decoration: const InputDecoration(
                        labelText: 'Contenu JSON',
                        alignLabelWithHint: true,
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remplacer les données existantes'),
                      value: replace,
                      onChanged: (value) {
                        setLocalState(() => replace = value ?? false);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restaurer'),
              ),
            ],
          );
        },
      ),
    );

    if (accepted != true) return;

    setState(() => busy = true);

    try {
      final decoded = jsonDecode(controller.text);

      if (decoded is! Map) {
        throw const FormatException('Le JSON doit contenir un objet.');
      }

      await AppDatabase.instance.importJson(
        Map<String, dynamic>.from(decoded),
        replaceExisting: replace,
      );

      await AppDatabase.instance.log(
        'backup.imported',
        data: {'replace_existing': replace},
      );

      message = 'Sauvegarde restaurée avec succès.';
    } catch (e) {
      message = '$e';
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
      controller.dispose();
    }
  }

  Future<void> createRouterBackup() async {
    setState(() => busy = true);

    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;

      await RouterSession.instance.service.createRouterBackup(
        'rmm_backup_$stamp',
      );

      await AppDatabase.instance.log(
        'router.backup.created',
        data: {'name': 'rmm_backup_$stamp'},
      );

      message = 'Backup RouterOS demandé.';
    } catch (e) {
      message = '$e';
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> exportRouterConfig() async {
    setState(() => busy = true);

    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;

      await RouterSession.instance.service.exportRouterConfig(
        'rmm_export_$stamp',
      );

      await AppDatabase.instance.log(
        'router.export.created',
        data: {'name': 'rmm_export_$stamp'},
      );

      message = 'Export RouterOS .rsc demandé.';
    } catch (e) {
      message = '$e';
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegardes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: busy ? null : exportAppJson,
            icon: const Icon(Icons.save_alt),
            label: const Text('Sauvegarder RootMikroManager en JSON'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : importJsonDialog,
            icon: const Icon(Icons.restore_page_outlined),
            label: const Text('Restaurer depuis un JSON'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () =>
                      AppRouter.pushNamed(context, AppRoutes.backupLegacyFiles),
            icon: const Icon(Icons.folder_outlined),
            label: const Text('Fichiers présents sur le routeur'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : createRouterBackup,
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Créer un backup RouterOS'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : exportRouterConfig,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Exporter la configuration RouterOS (.rsc)'),
          ),
          if (busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (message != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(message!),
              ),
            ),
          ],
          if (localPath != null) ...[
            const SizedBox(height: 8),
            SelectableText('Emplacement choisi : $localPath'),
          ],
        ],
      ),
    );
  }
}
