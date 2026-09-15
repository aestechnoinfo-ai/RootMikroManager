import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class DhcpServersScreen extends StatefulWidget {
  final RouterOsService service;
  const DhcpServersScreen({super.key, required this.service});

  @override
  State<DhcpServersScreen> createState() => _DhcpServersScreenState();
}

class _DhcpServersScreenState extends State<DhcpServersScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.dhcpServers();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.dhcpServerEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> action(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;

    if (action == 'edit') return edit(row);
    if (action == 'enable') {
      await widget.service.enable('/ip/dhcp-server', id);
    } else if (action == 'disable') {
      await widget.service.disable('/ip/dhcp-server', id);
    } else if (action == 'delete') {
      final label = row['name'] ?? id;
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer le serveur DHCP ?'),
              content: Text(
                '« $label » sera supprimé. Les clients de cette interface '
                'ne recevront plus de nouveaux baux via ce serveur.',
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
      await widget.service.remove('/ip/dhcp-server', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Serveurs DHCP'),
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
              label: const Text('Ajouter serveur DHCP'),
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
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      final disabled =
                          r['disabled'] == 'yes' || r['disabled'] == 'true';
                      final invalid =
                          r['invalid'] == 'yes' || r['invalid'] == 'true';

                      return Card(
                        child: ListTile(
                          onTap: () => edit(r),
                          leading: CircleAvatar(
                            child: Icon(
                              invalid
                                  ? Icons.error_outline
                                  : disabled
                                  ? Icons.pause
                                  : Icons.dns_outlined,
                            ),
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'Interface ${r['interface'] ?? '—'}',
                              'Pool ${r['address-pool'] ?? '—'}',
                              'Lease ${r['lease-time'] ?? '—'}',
                              if ((r['relay'] ?? '0.0.0.0') != '0.0.0.0')
                                'Relay ${r['relay']}',
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
}
