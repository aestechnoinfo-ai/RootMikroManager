import 'package:flutter/material.dart';

class ManagementValidationMatrixScreen extends StatelessWidget {
  const ManagementValidationMatrixScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Matrice de validation gestionnaire')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        _Item(
          'Hotspot / tickets',
          'Statique renforcé',
          'Routeur réel requis pour expiration, cookies et portail captif.',
        ),
        _Item(
          'Profils Hotspot',
          'Statique renforcé',
          'Tester création, modification et scheduler sur RouterOS réel.',
        ),
        _Item(
          'Vouchers / QR',
          'Statique renforcé',
          'Scanner un QR et ouvrir le portail captif réel.',
        ),
        _Item(
          'Impression PDF',
          'Statique renforcé',
          'Valider A4 et densités sur papier réel.',
        ),
        _Item(
          'Thermique 58/80',
          'Configuration prête',
          'Transport imprimante physique encore à valider/implémenter.',
        ),
        _Item(
          'PPP',
          'Statique renforcé',
          'Tester secrets, profils et sessions sur RouterOS réel.',
        ),
        _Item(
          'Ventes / rapports',
          'Statique renforcé',
          'Comparer CA et exports avec données réelles.',
        ),
        _Item(
          'APK / plateformes',
          'Différé',
          'Compilation Android/iOS à la phase build finale.',
        ),
      ],
    ),
  );
}

class _Item extends StatelessWidget {
  final String title, status, detail;
  const _Item(this.title, this.status, this.detail);
  @override
  Widget build(BuildContext c) => Card(
    child: ListTile(
      title: Text(title),
      subtitle: Text(detail),
      trailing: Text(status, textAlign: TextAlign.end),
    ),
  );
}
