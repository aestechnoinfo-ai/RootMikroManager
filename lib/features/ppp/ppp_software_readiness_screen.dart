import 'package:flutter/material.dart';

class PppSoftwareReadinessScreen extends StatelessWidget {
  const PppSoftwareReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pré-gel logiciel PPP')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        _Check(
          'Secrets',
          'CRUD, doublons, profil, IP/pool et service contrôlés.',
        ),
        _Check(
          'Profils',
          'CRUD, dépendances, pools, rate-limit et timeouts contrôlés.',
        ),
        _Check('Sessions', 'Liste et déconnexion disponibles.'),
        _Check(
          'Suppressions',
          'Profils/secrets protégés lorsqu’ils sont encore utilisés.',
        ),
        _Check('Exports', 'Mots de passe exclus par défaut.'),
        _Check(
          'Audits',
          'Orphelins, profils inutilisés et cohérence disponibles.',
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.schedule_outlined),
            title: Text('Validation RouterOS réelle'),
            subtitle: Text(
              'Différée ; elle ne bloque plus la construction logicielle.',
            ),
            trailing: Text('Plus tard'),
          ),
        ),
      ],
    ),
  );
}

class _Check extends StatelessWidget {
  final String title, detail;
  const _Check(this.title, this.detail);
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.check_circle_outline),
      title: Text(title),
      subtitle: Text(detail),
      trailing: const Text('Logiciel OK'),
    ),
  );
}
