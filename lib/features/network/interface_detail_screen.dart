import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class InterfaceDetailScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String> row;

  const InterfaceDetailScreen({
    super.key,
    required this.service,
    required this.row,
  });

  @override
  State<InterfaceDetailScreen> createState() => _InterfaceDetailScreenState();
}

class _InterfaceDetailScreenState extends State<InterfaceDetailScreen> {
  late Map<String, String> row;
  Map<String, String> ethernetMonitor = {};
  bool liveLoading = false;

  @override
  void initState() {
    super.initState();
    row = Map<String, String>.from(widget.row);
    loadPhysicalStatus();
  }

  Future<void> loadPhysicalStatus() async {
    final name = row['name'] ?? '';
    if (name.isEmpty) return;
    if (mounted) setState(() => liveLoading = true);
    ethernetMonitor = await widget.service.interfaceEthernetMonitorOnce(name);
    if (mounted) setState(() => liveLoading = false);
  }

  Future<void> edit() async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.interfaceEdit,
      extra: RequiredRowPayload(row),
    );
    if (changed == true) {
      final all = await widget.service.interfaces();
      final id = row['.id'];
      final fresh = all.where((e) => e['.id'] == id).toList();
      if (fresh.isNotEmpty && mounted) {
        setState(() => row = fresh.first);
        await loadPhysicalStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = row.entries
        .where((e) => e.key != '.id' && e.value.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(row['name'] ?? 'Interface'),
        actions: [
          IconButton(
            tooltip: 'Actualiser le lien physique',
            onPressed: loadPhysicalStatus,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Modifier',
            onPressed: edit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.settings_input_component_outlined),
              ),
              title: Text(row['name'] ?? '—'),
              subtitle: Text(
                [
                  if ((row['type'] ?? '').isNotEmpty) row['type']!,
                  if ((row['mac-address'] ?? '').isNotEmpty)
                    'MAC ${row['mac-address']}',
                  if ((row['mtu'] ?? '').isNotEmpty) 'MTU ${row['mtu']}',
                ].join(' • '),
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () => AppRouter.pushNamed(
              context,
              AppRoutes.monitorInterfaces,
              extra: InterfaceMonitorPayload(row['name'] ?? ''),
            ),
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Ouvrir le monitoring RX/TX'),
          ),
          const SizedBox(height: 10),
          if (liveLoading) const LinearProgressIndicator(),
          if (ethernetMonitor.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if ((ethernetMonitor['status'] ?? '').isNotEmpty)
                      Text('Link ${ethernetMonitor['status']}'),
                    if ((ethernetMonitor['rate'] ?? '').isNotEmpty)
                      Text('Rate ${ethernetMonitor['rate']}'),
                    if ((ethernetMonitor['full-duplex'] ?? '').isNotEmpty)
                      Text(
                        'Duplex ${ethernetMonitor['full-duplex'] == 'yes' ? 'full' : 'half'}',
                      ),
                    if ((ethernetMonitor['auto-negotiation'] ?? '').isNotEmpty)
                      Text('Auto-neg ${ethernetMonitor['auto-negotiation']}'),
                  ],
                ),
              ),
            ),
          for (final e in entries)
            Card(
              child: ListTile(
                title: Text(e.key),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: SelectableText(e.value, textAlign: TextAlign.right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
