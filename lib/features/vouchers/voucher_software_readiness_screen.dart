import 'package:flutter/material.dart';

class VoucherSoftwareReadinessScreen extends StatelessWidget {
  const VoucherSoftwareReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pré-gel logiciel vouchers')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        _Check(
          'Tickets / profils séparés',
          true,
          'Les opérations ticket ne ciblent pas les profils Hotspot.',
        ),
        _Check(
          'Expiration sécurisée',
          true,
          'Cookie → session active → scheduler → ticket.',
        ),
        _Check(
          'Génération par lot',
          true,
          'Limite logicielle cohérente avec Mikhmon : 1 à 560 tickets.',
        ),
        _Check(
          'Réimpression',
          true,
          'Une réimpression ne crée ni ticket ni vente.',
        ),
        _Check(
          'Devise',
          true,
          'Devise centralisée dans prix, rapports et impression.',
        ),
        _Check(
          'PDF / densité',
          true,
          'A4 jusqu’à 50 ; thermique jusqu’à 2 ; QR masqué à forte densité.',
        ),
        _Check(
          'Portail / QR réel',
          false,
          'Validation matérielle différée comme prévu.',
        ),
        _Check(
          'Imprimante physique',
          false,
          'Validation matérielle différée comme prévu.',
        ),
      ],
    ),
  );
}

class _Check extends StatelessWidget {
  final String title;
  final bool softwareReady;
  final String detail;
  const _Check(this.title, this.softwareReady, this.detail);

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        softwareReady ? Icons.check_circle_outline : Icons.schedule_outlined,
      ),
      title: Text(title),
      subtitle: Text(detail),
      trailing: Text(softwareReady ? 'Logiciel OK' : 'Plus tard'),
    ),
  );
}
