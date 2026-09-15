import 'package:flutter/material.dart';
import 'voucher_generation_batch_result.dart';

class VoucherGenerationResultScreen extends StatelessWidget {
  final VoucherGenerationBatchResult result;
  const VoucherGenerationResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Résultat de génération')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              result.complete
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_outlined,
            ),
            title: Text('${result.generated}/${result.requested} généré(s)'),
            subtitle: Text(
              result.complete
                  ? 'Le lot a été créé entièrement.'
                  : '${result.failed} ticket(s) non généré(s).',
            ),
          ),
        ),
        if (result.error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText('Erreur : ${result.error}'),
            ),
          ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Les tickets déjà créés avant une erreur restent valides. '
              'RootMikroManager ne les recrée pas automatiquement afin '
              'd’éviter les doublons.',
            ),
          ),
        ),
      ],
    ),
  );
}
