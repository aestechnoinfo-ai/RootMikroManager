import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class TracerouteAdvancedScreen extends StatefulWidget {
  final RouterOsService service;
  const TracerouteAdvancedScreen({super.key, required this.service});

  @override
  State<TracerouteAdvancedScreen> createState() =>
      _TracerouteAdvancedScreenState();
}

class _TracerouteAdvancedScreenState extends State<TracerouteAdvancedScreen> {
  final address = TextEditingController(text: '8.8.8.8');
  final maxHops = TextEditingController(text: '30');
  bool running = false;
  List<Map<String, String>> rows = [];

  Future<void> run() async {
    if (address.text.trim().isEmpty || running) return;
    setState(() {
      running = true;
      rows = [];
    });
    try {
      rows = await widget.service.tracerouteAdvanced(
        address.text.trim(),
        maxHops: int.tryParse(maxHops.text.trim()) ?? 30,
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
    appBar: AppBar(title: const Text('Traceroute')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: address,
          decoration: const InputDecoration(labelText: 'Destination'),
          onSubmitted: (_) => run(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: maxHops,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Max Hops'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: running ? null : run,
          icon: const Icon(Icons.alt_route),
          label: const Text('Tracer la route'),
        ),
        const SizedBox(height: 16),
        if (running) const Center(child: CircularProgressIndicator()),
        for (var i = 0; i < rows.length; i++)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(rows[i]['address'] ?? rows[i]['host'] ?? '*'),
              subtitle: Text(
                [
                  if ((rows[i]['status'] ?? '').isNotEmpty) rows[i]['status']!,
                  if ((rows[i]['loss'] ?? '').isNotEmpty)
                    'Loss ${rows[i]['loss']}',
                  if ((rows[i]['avg'] ?? '').isNotEmpty)
                    'Avg ${rows[i]['avg']}',
                  if ((rows[i]['last'] ?? '').isNotEmpty)
                    'Last ${rows[i]['last']}',
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
    maxHops.dispose();
    super.dispose();
  }
}
