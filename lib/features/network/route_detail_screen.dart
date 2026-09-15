import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String> row;

  const RouteDetailScreen({
    super.key,
    required this.service,
    required this.row,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  bool loading = true;
  Map<String, String> detail = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final id = widget.row['.id'] ?? '';
    final dst = widget.row['dst-address'] ?? '';
    final gateway = widget.row['gateway'] ?? '';
    final all = await widget.service.routingRoutesDetailed();
    var matches = id.isEmpty
        ? <Map<String, String>>[]
        : all.where((r) => r['.id'] == id).toList();
    if (matches.isEmpty) {
      matches = all.where((r) {
        if (dst.isNotEmpty && r['dst-address'] != dst) return false;
        if (gateway.isNotEmpty && (r['gateway'] ?? '') != gateway) return false;
        return true;
      }).toList();
    }
    detail = matches.isNotEmpty ? matches.first : widget.row;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.row['dst-address'] ?? 'Détail route'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.alt_route)),
                  title: Text(detail['dst-address'] ?? '—'),
                  subtitle: Text(
                    [
                      'Gateway ${detail['gateway'] ?? '—'}',
                      if ((detail['immediate-gw'] ?? '').isNotEmpty)
                        'Immediate ${detail['immediate-gw']}',
                      if ((detail['routing-table'] ?? '').isNotEmpty)
                        'Table ${detail['routing-table']}',
                    ].join(' • '),
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _flag('Active', detail['active']),
                      _flag('Dynamic', detail['dynamic']),
                      _flag('Disabled', detail['disabled']),
                      _flag('HW offload', detail['hw-offloaded']),
                      if ((detail['distance'] ?? '').isNotEmpty)
                        Text('Distance ${detail['distance']}'),
                      if ((detail['scope'] ?? '').isNotEmpty)
                        Text('Scope ${detail['scope']}'),
                      if ((detail['target-scope'] ?? '').isNotEmpty)
                        Text('Target ${detail['target-scope']}'),
                    ],
                  ),
                ),
              ),
              for (final e in detail.entries.where(
                (e) => e.key != '.id' && e.value.isNotEmpty,
              ))
                Card(
                  child: ListTile(
                    title: Text(e.key),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 230),
                      child: SelectableText(
                        e.value,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ),
            ],
          ),
  );

  Widget _flag(String label, String? value) {
    final on = value == 'yes' || value == 'true';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          on ? Icons.check_circle_outline : Icons.remove_circle_outline,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
