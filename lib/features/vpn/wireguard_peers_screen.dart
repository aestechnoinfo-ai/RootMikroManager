import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'wireguard_peer_editor_screen.dart';

class WireGuardPeersScreen extends StatefulWidget {
  final RouterOsService service;
  final String interfaceName;

  const WireGuardPeersScreen({
    super.key,
    required this.service,
    required this.interfaceName,
  });

  @override
  State<WireGuardPeersScreen> createState() => _WireGuardPeersScreenState();
}

class _WireGuardPeersScreenState extends State<WireGuardPeersScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final all = await widget.service.wireGuardPeers();
    rows = all
        .where((e) => (e['interface'] ?? '') == widget.interfaceName)
        .toList();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.wireGuardPeerEdit,
      extra: WireGuardPeerEditPayload(
        interfaceName: widget.interfaceName,
        row: row,
      ),
    );
    if (changed == true) await load();
  }

  Future<void> action(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final disabled = row['disabled'] == 'yes' || row['disabled'] == 'true';

    if (action == 'edit') return edit(row);
    if (action == 'toggle') {
      if (disabled) {
        await widget.service.enable('/interface/wireguard/peers', id);
      } else {
        await widget.service.disable('/interface/wireguard/peers', id);
      }
    } else if (action == 'delete') {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer ce peer ?'),
              content: Text(
                '${row['allowed-address'] ?? '—'}\n\n'
                'Cette suppression peut rendre un réseau distant immédiatement injoignable.',
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
      await widget.service.remove('/interface/wireguard/peers', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Peers ${widget.interfaceName}'),
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
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Ajouter peer'),
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

                      return Card(
                        child: ListTile(
                          onTap: () => edit(r),
                          leading: const CircleAvatar(
                            child: Icon(Icons.key_outlined),
                          ),
                          title: Text(
                            (r['name'] ?? '').isNotEmpty
                                ? r['name']!
                                : r['comment'] ?? 'Peer',
                          ),
                          subtitle: Text(
                            [
                              r['allowed-address'] ?? '—',
                              if ((r['last-handshake'] ?? '').isNotEmpty)
                                'Handshake ${r['last-handshake']}',
                              if ((r['rx'] ?? '').isNotEmpty) 'RX ${r['rx']}',
                              if ((r['tx'] ?? '').isNotEmpty) 'TX ${r['tx']}',
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
                                value: 'toggle',
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
