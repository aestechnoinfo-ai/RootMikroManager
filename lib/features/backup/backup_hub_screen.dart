import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';

class BackupHubScreen extends StatelessWidget {
  const BackupHubScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sauvegarde & restauration')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Les sauvegardes de l’application et celles de RouterOS sont '
              'séparées. Un backup .backup restaure le routeur, tandis que '
              'le JSON RootMikroManager sauvegarde les données locales.',
            ),
          ),
        ),
        const SizedBox(height: 8),
        _button(
          context,
          'Sauvegarde RootMikroManager',
          'JSON local : routeurs, historique vouchers, paramètres et audit',
          Icons.phone_android_outlined,
          AppRoutes.backupApp,
        ),
        _button(
          context,
          'Backup RouterOS',
          'Création .backup et export texte .rsc',
          Icons.backup_outlined,
          AppRoutes.backupRouter,
        ),
        _button(
          context,
          'Fichiers RouterOS',
          'Inventaire, recherche, suppression et restauration .backup',
          Icons.folder_outlined,
          AppRoutes.backupRouterFiles,
        ),
        _button(
          context,
          'Exporter la configuration',
          'Générer un export RouterOS .rsc',
          Icons.file_download_outlined,
          AppRoutes.backupRouterExport,
        ),
      ],
    ),
  );

  Widget _button(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String routeName,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton.tonalIcon(
      onPressed: () => AppRouter.pushNamed(context, routeName),
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}
