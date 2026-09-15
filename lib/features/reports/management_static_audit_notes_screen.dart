import 'package:flutter/material.dart';

class ManagementStaticAuditNotesScreen extends StatelessWidget {
  const ManagementStaticAuditNotesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Périmètre de validation')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        _Section(
          'Validé statiquement',
          'Imports relatifs, structure des fichiers, séparation tickets/profils, '
              'absence de bouton flottant, ancienne marque absente, règles de cycle '
              'de vie, devise, déduplication des ventes et protections PPP.',
        ),
        _Section(
          'Non validé sans SDK',
          'flutter analyze, compilation Dart/Flutter, tests unitaires exécutés '
              'par le SDK et compilation des plateformes.',
        ),
        _Section(
          'Non validé sans matériel',
          'Commandes RouterOS sur routeur réel, expiration captive portal, '
              'MAC-cookie, QR de connexion, rendu papier et imprimantes thermiques.',
        ),
        _Section(
          'Conséquence',
          'Le développement peut continuer vers les autres modules sans '
              'présenter ces éléments différés comme déjà testés.',
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  final String title, body;
  const _Section(this.title, this.body);
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    ),
  );
}
