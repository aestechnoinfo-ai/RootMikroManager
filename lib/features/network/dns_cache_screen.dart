import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class DnsCacheScreen extends StatefulWidget {
  final RouterOsService service;
  const DnsCacheScreen({super.key, required this.service});

  @override
  State<DnsCacheScreen> createState() => _DnsCacheScreenState();
}

class _DnsCacheScreenState extends State<DnsCacheScreen> {
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
    rows = await widget.service.dnsCacheAll();
    if (mounted) setState(() => loading = false);
  }

  Future<void> flush() async {
    await widget.service.flushDnsCache();
    await load();
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
      title: Text('Cache DNS (${rows.length})'),
      actions: [
        IconButton(
          tooltip: 'Vider le cache',
          onPressed: flush,
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Nom, données, type…',
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
                        child: ListTile(
                          leading: CircleAvatar(child: Text(r['type'] ?? '?')),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              if ((r['data'] ?? '').isNotEmpty) r['data']!,
                              if ((r['address'] ?? '').isNotEmpty)
                                r['address']!,
                              if ((r['ttl'] ?? '').isNotEmpty)
                                'TTL ${r['ttl']}',
                            ].join(' • '),
                          ),
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
