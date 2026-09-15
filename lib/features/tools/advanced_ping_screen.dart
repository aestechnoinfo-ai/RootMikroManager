import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class AdvancedPingScreen extends StatefulWidget {
  final RouterOsService service;
  const AdvancedPingScreen({super.key, required this.service});

  @override
  State<AdvancedPingScreen> createState() => _AdvancedPingScreenState();
}

class _AdvancedPingScreenState extends State<AdvancedPingScreen> {
  final address = TextEditingController(text: '8.8.8.8');
  final count = TextEditingController(text: '5');
  final size = TextEditingController(text: '56');
  final interval = TextEditingController(text: '1s');
  final srcAddress = TextEditingController();
  final routingTable = TextEditingController();
  bool running = false;
  List<Map<String, String>> rows = [];

  Future<void> run() async {
    if (address.text.trim().isEmpty || running) return;
    setState(() {
      running = true;
      rows = [];
    });
    try {
      rows = await widget.service.pingAdvanced(
        address: address.text.trim(),
        count: int.tryParse(count.text.trim()) ?? 5,
        size: int.tryParse(size.text.trim()) ?? 56,
        interval: interval.text.trim(),
        srcAddress: srcAddress.text.trim(),
        routingTable: routingTable.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ping avancé')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: address,
          decoration: const InputDecoration(labelText: 'Adresse / domaine'),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (_, c) {
            final a = TextField(
              controller: count,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Count'),
            );
            final b = TextField(
              controller: size,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Size'),
            );
            final d = TextField(
              controller: interval,
              decoration: const InputDecoration(labelText: 'Interval'),
            );
            if (c.maxWidth < 620) {
              return Column(
                children: [
                  a,
                  const SizedBox(height: 8),
                  b,
                  const SizedBox(height: 8),
                  d,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: a),
                const SizedBox(width: 8),
                Expanded(child: b),
                const SizedBox(width: 8),
                Expanded(child: d),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: srcAddress,
          decoration: const InputDecoration(
            labelText: 'Source Address',
            helperText: 'Optionnel',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: routingTable,
          decoration: const InputDecoration(
            labelText: 'Routing Table',
            helperText: 'Optionnel',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: running ? null : run,
          icon: const Icon(Icons.network_ping),
          label: const Text('Lancer le ping'),
        ),
        const SizedBox(height: 16),
        if (running) const Center(child: CircularProgressIndicator()),
        for (final r in rows)
          Card(
            child: ListTile(
              leading: const Icon(Icons.speed),
              title: Text(r['host'] ?? r['address'] ?? 'Réponse'),
              subtitle: Text(
                [
                  if ((r['time'] ?? '').isNotEmpty) 'RTT ${r['time']}',
                  if ((r['ttl'] ?? '').isNotEmpty) 'TTL ${r['ttl']}',
                  if ((r['packet-loss'] ?? '').isNotEmpty)
                    'Perte ${r['packet-loss']}%',
                  if ((r['status'] ?? '').isNotEmpty) r['status']!,
                ].join(' • '),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  void dispose() {
    address.dispose();
    count.dispose();
    size.dispose();
    interval.dispose();
    srcAddress.dispose();
    routingTable.dispose();
    super.dispose();
  }
}
