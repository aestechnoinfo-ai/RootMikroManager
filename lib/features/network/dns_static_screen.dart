import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class DnsStaticScreen extends StatefulWidget {
  final RouterOsService service;
  const DnsStaticScreen({super.key, required this.service});

  @override
  State<DnsStaticScreen> createState() => _DnsStaticScreenState();
}

class _DnsStaticScreenState extends State<DnsStaticScreen> {
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
    rows = await widget.service.dnsStatic();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.dnsStaticEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> action(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    if (action == 'edit') return edit(row);
    if (action == 'enable') {
      await widget.service.enable('/ip/dns/static', id);
    } else if (action == 'disable') {
      await widget.service.disable('/ip/dns/static', id);
    } else if (action == 'delete') {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer l’entrée DNS ?'),
              content: Text(
                '« ${row['name'] ?? row['regexp'] ?? id} » sera supprimée.',
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
      if (!ok) return;
      await widget.service.remove('/ip/dns/static', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('DNS statique'),
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
              labelText: 'Nom, adresse, type, commentaire…',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter entrée DNS'),
            ),
          ),
        ),
        const SizedBox(height: 8),
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
                      final disabled =
                          r['disabled'] == 'yes' || r['disabled'] == 'true';
                      return Card(
                        child: ListTile(
                          onTap: () => edit(r),
                          leading: CircleAvatar(child: Text(r['type'] ?? 'A')),
                          title: Text(r['name'] ?? r['regexp'] ?? 'Entrée DNS'),
                          subtitle: Text(
                            [
                              if ((r['address'] ?? '').isNotEmpty)
                                r['address']!,
                              if ((r['forward-to'] ?? '').isNotEmpty)
                                'FWD ${r['forward-to']}',
                              if ((r['ttl'] ?? '').isNotEmpty)
                                'TTL ${r['ttl']}',
                              if ((r['comment'] ?? '').isNotEmpty)
                                r['comment']!,
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => action(v, r),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Modifier'),
                              ),
                              PopupMenuItem(
                                value: disabled ? 'enable' : 'disable',
                                child: Text(
                                  disabled ? 'Activer' : 'Désactiver',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                            ],
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
