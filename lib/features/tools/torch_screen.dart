import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class TorchScreen extends StatefulWidget {
  final RouterOsService service;
  const TorchScreen({super.key, required this.service});

  @override
  State<TorchScreen> createState() => _TorchScreenState();
}

class _TorchScreenState extends State<TorchScreen> {
  bool loading = true;
  bool running = false;
  String interfaceName = '';
  List<String> interfaces = [];
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    loadInterfaces();
  }

  Future<void> loadInterfaces() async {
    interfaces = (await widget.service.interfaces())
        .map((e) => e['name'] ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    if (interfaces.isNotEmpty) interfaceName = interfaces.first;
    if (mounted) setState(() => loading = false);
  }

  Future<void> run() async {
    if (interfaceName.isEmpty || running) return;
    setState(() {
      running = true;
      rows = [];
    });
    try {
      rows = await widget.service.torchOnce(interfaceName);
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
    appBar: AppBar(title: const Text('Torch')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              DropdownButtonFormField<String>(isExpanded: true, 
                value: interfaces.contains(interfaceName)
                    ? interfaceName
                    : null,
                decoration: const InputDecoration(labelText: 'Interface'),
                items: interfaces
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => interfaceName = v ?? interfaceName),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: running ? null : run,
                icon: const Icon(Icons.local_fire_department_outlined),
                label: const Text('Analyser le trafic'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Torch observe le trafic passant par l’interface. '
                'Le trafic traité intégralement par hardware offload peut '
                'ne pas apparaître.',
              ),
              const SizedBox(height: 12),
              if (running) const Center(child: CircularProgressIndicator()),
              for (final r in rows)
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.swap_vert),
                    title: Text(
                      [
                        r['src-address'] ?? '',
                        r['dst-address'] ?? '',
                      ].where((e) => e.isNotEmpty).join(' → '),
                    ),
                    subtitle: Text(
                      [
                        if ((r['protocol'] ?? '').isNotEmpty) r['protocol']!,
                        if ((r['tx'] ?? r['tx-rate'] ?? '').isNotEmpty)
                          'TX ${r['tx'] ?? r['tx-rate']}',
                        if ((r['rx'] ?? r['rx-rate'] ?? '').isNotEmpty)
                          'RX ${r['rx'] ?? r['rx-rate']}',
                      ].join(' • '),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          r.entries
                              .where((e) => e.value.isNotEmpty)
                              .map((e) => '${e.key}: ${e.value}')
                              .join('\n'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );
}
