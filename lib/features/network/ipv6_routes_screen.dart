import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class Ipv6RoutesScreen extends StatefulWidget {
  final RouterOsService service;
  const Ipv6RoutesScreen({super.key, required this.service});
  @override
  State<Ipv6RoutesScreen> createState() => _State();
}

class _State extends State<Ipv6RoutesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.ipv6Routes();
    if (mounted) setState(() => loading = false);
  }

  bool dynamic(Map<String, String> r) =>
      r['dynamic'] == 'yes' || (r['flags'] ?? '').contains('D');
  Future<void> edit([Map<String, String>? r]) async {
    if (r != null && dynamic(r)) return;
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.ipv6RouteEdit,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> removeRoute(Map<String, String> r) async {
    if (dynamic(r)) return;
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cette route IPv6 ?'),
            content: Text(
              '${r['dst-address'] ?? '—'} → ${r['gateway'] ?? '—'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await widget.service.remove('/ipv6/route', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text('Routes IPv6 (${rows.length})'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une route IPv6'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final r in rows)
                      Card(
                        child: ListTile(
                          onTap: dynamic(r) ? null : () => edit(r),
                          leading: Icon(
                            dynamic(r) ? Icons.auto_awesome : Icons.route,
                          ),
                          title: Text(r['dst-address'] ?? '—'),
                          subtitle: Text(
                            '${r['gateway'] ?? '—'} • table ${r['routing-table'] ?? 'main'} • distance ${r['distance'] ?? '—'}',
                          ),
                          trailing: dynamic(r)
                              ? const Chip(label: Text('dynamique'))
                              : IconButton(
                                  onPressed: () => removeRoute(r),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
