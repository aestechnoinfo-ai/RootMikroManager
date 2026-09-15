import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class QueueStatsScreen extends StatefulWidget {
  final RouterOsService service;
  const QueueStatsScreen({super.key, required this.service});

  @override
  State<QueueStatsScreen> createState() => _QueueStatsScreenState();
}

class _QueueStatsScreenState extends State<QueueStatsScreen> {
  bool loading = true;
  int simple = 0;
  int tree = 0;
  int types = 0;
  int disabled = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final result = await Future.wait([
      widget.service.simpleQueues(),
      widget.service.queueTree(),
      widget.service.queueTypes(),
    ]);
    simple = result[0].length;
    tree = result[1].length;
    types = result[2].length;
    disabled = [
      ...result[0],
      ...result[1],
    ].where((r) => r['disabled'] == 'yes' || r['disabled'] == 'true').length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Queues — statistiques'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _card('Simple Queues', simple, Icons.speed),
              _card('Queue Tree', tree, Icons.account_tree_outlined),
              _card('Queue Types', types, Icons.tune),
              _card('Queues désactivées', disabled, Icons.pause_circle_outline),
            ],
          ),
  );

  Widget _card(String label, int value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text('$value', style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
