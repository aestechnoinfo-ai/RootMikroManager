import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class IpNeighborsScreen extends StatefulWidget {
  final RouterOsService service;
  const IpNeighborsScreen({super.key, required this.service});

  @override
  State<IpNeighborsScreen> createState() => _IpNeighborsScreenState();
}

class _IpNeighborsScreenState extends State<IpNeighborsScreen> {
  final search = TextEditingController();
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.neighbors();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('IP Neighbors (${rows.length})'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Identity, IP, MAC, interface…',
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final r = visible[i];
                      return Card(
                        child: ExpansionTile(
                          leading: const Icon(Icons.radar),
                          title: Text(
                            r['identity'] ??
                                r['system-description'] ??
                                'Neighbor',
                          ),
                          subtitle: Text(
                            [
                              if ((r['address'] ?? '').isNotEmpty)
                                r['address']!,
                              if ((r['mac-address'] ?? '').isNotEmpty)
                                'MAC ${r['mac-address']}',
                              if ((r['interface'] ?? '').isNotEmpty)
                                r['interface']!,
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
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
