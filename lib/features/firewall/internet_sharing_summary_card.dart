import 'package:flutter/material.dart';
import 'internet_sharing_status.dart';

class InternetSharingSummaryCard extends StatelessWidget {
  final InternetSharingStatus status;
  const InternetSharingSummaryCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 430;
          final items = [
            _Metric(
              'Interfaces',
              status.protectedInterfaces,
              Icons.router_outlined,
            ),
            _Metric('Actives', status.enabledRules, Icons.block_outlined),
            _Metric(
              'Suspendues',
              status.disabledRules,
              Icons.pause_circle_outline,
            ),
          ];

          if (compact) {
            return Column(
              children: [
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    trailing: Text(
                      '${item.value}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
              ],
            );
          }

          return Row(
            children: [
              for (final item in items)
                Expanded(
                  child: Column(
                    children: [
                      Icon(item.icon),
                      const SizedBox(height: 6),
                      Text(item.label),
                      Text(
                        '${item.value}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _Metric {
  final String label;
  final int value;
  final IconData icon;
  const _Metric(this.label, this.value, this.icon);
}
