import 'package:flutter/material.dart';

class ManagerSoftwareFreezeScreen extends StatelessWidget {
  const ManagerSoftwareFreezeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gel logiciel gestionnaire')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Cette page marque la fin de la consolidation statique de la '
              'branche gestionnaire. Elle ne signifie pas que les tests '
              'réels RouterOS, portail, impression ou plateformes ont été faits.',
            ),
          ),
        ),
        _Row('Hotspot / tickets', 'Pré-gel logiciel atteint'),
        _Row('Profils / expiration', 'Pré-gel logiciel atteint'),
        _Row('Vouchers / historique', 'Pré-gel logiciel atteint'),
        _Row('Ventes / rapports', 'Pré-gel logiciel atteint'),
        _Row('Impression / PDF', 'Pré-gel logiciel atteint'),
        _Row('PPP / PPPoE', 'Pré-gel logiciel atteint'),
        _Row('Devise / exports', 'Pré-gel logiciel atteint'),
        _Row('Tests routeur / portail / imprimante', 'Différés'),
        _Row('Build Android / iOS', 'Différé'),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final String area, status;
  const _Row(this.area, this.status);
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(area),
      trailing: Text(status, textAlign: TextAlign.end),
    ),
  );
}
