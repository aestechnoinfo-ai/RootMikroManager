import 'package:flutter/material.dart';
import 'voucher_batch_action_result.dart';

class VoucherBatchLifecycleResultScreen extends StatelessWidget {
  final String title;
  final VoucherBatchActionResult result;

  const VoucherBatchLifecycleResultScreen({
    super.key,
    required this.title,
    required this.result,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            title: const Text('Résultat du lot'),
            subtitle: Text(
              '${result.successCount} succès • '
              '${result.failureCount} échec(s)',
            ),
            leading: Icon(
              result.hasFailures
                  ? Icons.warning_amber_outlined
                  : Icons.check_circle_outline,
            ),
          ),
        ),
        for (final item in result.items)
          Card(
            child: ListTile(
              leading: Icon(
                item.success ? Icons.check_circle_outline : Icons.error_outline,
              ),
              title: Text(item.username),
              subtitle: Text(item.message),
            ),
          ),
      ],
    ),
  );
}
