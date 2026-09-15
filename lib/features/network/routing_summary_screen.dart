import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RoutingSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const RoutingSummaryScreen({super.key, required this.service});

  @override
  State<RoutingSummaryScreen> createState() => _RoutingSummaryScreenState();
}

class _RoutingSummaryScreenState extends State<RoutingSummaryScreen> {
  bool loading = true;
  int routes = 0,
      staticRoutes = 0,
      dynamicRoutes = 0,
      activeRoutes = 0,
      inactiveRoutes = 0,
      arp = 0,
      arpFailed = 0,
      addresses = 0;

  bool yes(Map<String, String> r, String k) => r[k] == 'yes' || r[k] == 'true';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final result = await Future.wait([
      widget.service.ipRoutes(),
      widget.service.arpEntries(),
      widget.service.ipAddresses(),
    ]);

    routes = result[0].length;
    staticRoutes = result[0].where((r) => !yes(r, 'dynamic')).length;
    dynamicRoutes = routes - staticRoutes;
    activeRoutes = result[0].where((r) => yes(r, 'active')).length;
    inactiveRoutes = routes - activeRoutes;
    arp = result[1].length;
    arpFailed = result[1].where((r) => (r['status'] ?? '') == 'failed').length;
    addresses = result[2].length;

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé routage & IP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _c('Routes IPv4', routes, Icons.alt_route),
              _c('Routes statiques', staticRoutes, Icons.route_outlined),
              _c('Routes dynamiques', dynamicRoutes, Icons.bolt_outlined),
              _c('Routes actives', activeRoutes, Icons.check_circle_outline),
              _c(
                'Routes inactives',
                inactiveRoutes,
                Icons.pause_circle_outline,
              ),
              _c('Entrées ARP', arp, Icons.link_outlined),
              _c('ARP en échec', arpFailed, Icons.error_outline),
              _c('Adresses IP', addresses, Icons.language_outlined),
            ],
          ),
  );

  Widget _c(String l, int v, IconData i) => Card(
    child: ListTile(
      leading: Icon(i),
      title: Text(l),
      trailing: Text('$v', style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
