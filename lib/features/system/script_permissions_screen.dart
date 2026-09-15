import 'package:flutter/material.dart';

class ScriptPermissionsScreen extends StatelessWidget {
  const ScriptPermissionsScreen({super.key});
  static const rows = <String, String>{
    'read': 'Lire la configuration et l’état.',
    'write': 'Modifier la configuration.',
    'policy': 'Gérer utilisateurs et permissions.',
    'test': 'Ping, traceroute, bandwidth test.',
    'sniff': 'Torch et Packet Sniffer.',
    'ftp': 'Opérations de fichiers/FTP.',
    'reboot': 'Redémarrer le routeur.',
    'password': 'Modifier des mots de passe.',
    'sensitive': 'Accéder/modifier certains paramètres sensibles.',
    'romon': 'Utiliser RoMON.',
  };
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Permissions scripts')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'RouterOS distingue les permissions du script, de l’utilisateur appelant et du Scheduler. Un script qui fonctionne manuellement peut échouer depuis Scheduler si les policies du contexte d’exécution sont insuffisantes.',
            ),
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Avec /system script run, l’exécution normale utilise les droits de l’utilisateur appelant. L’option use-script-permissions demande les permissions propres du script. Un script ne peut pas contourner les droits du contexte appelant en demandant davantage de policies.',
            ),
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'dont-require-permissions diminue certains contrôles et ne doit pas être utilisé comme solution générale à un problème de permissions.',
            ),
          ),
        ),
        for (final e in rows.entries)
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(e.key),
              subtitle: Text(e.value),
            ),
          ),
      ],
    ),
  );
}
