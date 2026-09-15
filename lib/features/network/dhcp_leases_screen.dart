import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class DhcpLeasesScreen extends StatefulWidget {
  final RouterOsService service;
  const DhcpLeasesScreen({super.key, required this.service});

  @override
  State<DhcpLeasesScreen> createState() => _DhcpLeasesScreenState();
}

class _DhcpLeasesScreenState extends State<DhcpLeasesScreen> {
  final search = TextEditingController();
  List<Map<String, String>> leases = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    search.addListener(_refreshLocal);
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      leases = await widget.service.dhcpLeases();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get shown {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return leases;
    return leases.where((row) {
      return [
        row['address'],
        row['mac-address'],
        row['server'],
        row['active-address'],
        row['active-mac-address'],
        row['host-name'],
        row['status'],
        row['comment'],
      ].any((v) => (v ?? '').toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('DHCP Leases (${leases.length})'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: FilledButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh),
              label: Text(error!),
            ),
          )
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                _summary(),
                const SizedBox(height: 10),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: Text('Aucun bail DHCP pour ce filtre.'),
                    ),
                  ),
                ...shown.map(_card),
              ],
            ),
          ),
  );

  Widget _summary() {
    final dynamicCount = leases.where((r) => r['dynamic'] == 'true').length;
    final staticCount = leases.length - dynamicCount;
    final boundCount = leases.where((r) => r['status'] == 'bound').length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 720
            ? 4
            : width >= 360
            ? 2
            : 1;
        final itemWidth = (width - ((columns - 1) * 8)) / columns;
        final data = [
          ('Total', '${leases.length}', Icons.list_alt_outlined),
          ('Dynamiques', '$dynamicCount', Icons.bolt_outlined),
          ('Statiques', '$staticCount', Icons.push_pin_outlined),
          ('Bound', '$boundCount', Icons.link_outlined),
        ];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in data)
              SizedBox(
                width: itemWidth,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(item.$3),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$1),
                              Text(
                                item.$2,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _card(Map<String, String> lease) {
    final dynamic = lease['dynamic'] == 'true';
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(dynamic ? 'D' : 'S')),
        title: Text(lease['address'] ?? '—'),
        subtitle: Text(
          [
            'MAC: ${lease['mac-address'] ?? '—'}',
            'Server: ${lease['server'] ?? '—'}',
            'Active IP: ${lease['active-address'] ?? '—'}',
            'Active MAC: ${lease['active-mac-address'] ?? '—'}',
            'Host: ${lease['host-name'] ?? '—'}',
            'Status: ${lease['status'] ?? '—'}',
            if ((lease['comment'] ?? '').isNotEmpty)
              'Comment: ${lease['comment']}',
          ].join(' • '),
        ),
      ),
    );
  }

  void _refreshLocal() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    search.removeListener(_refreshLocal);
    search.dispose();
    super.dispose();
  }
}
