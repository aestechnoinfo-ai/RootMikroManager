import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class WireGuardInterfacesScreen extends StatefulWidget {
  final RouterOsService service;
  const WireGuardInterfacesScreen({super.key, required this.service});

  @override
  State<WireGuardInterfacesScreen> createState() =>
      _WireGuardInterfacesScreenState();
}

class _WireGuardInterfacesScreenState extends State<WireGuardInterfacesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.wireGuardInterfaces();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.wireguardInterfaceEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> action(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;

    final disabled = row['disabled'] == 'yes' || row['disabled'] == 'true';

    if (action == 'peers') {
      await AppRouter.pushNamed(
        context,
        AppRoutes.wireguardPeers,
        extra: WireGuardPeersPayload(row['name'] ?? ''),
      );
      return;
    }
    if (action == 'edit') return edit(row);
    if (action == 'toggle') {
      if (disabled) {
        await widget.service.enable('/interface/wireguard', id);
      } else {
        await widget.service.disable('/interface/wireguard', id);
      }
    } else if (action == 'delete') {
      final name = row['name'] ?? '';
      final peers = name.isEmpty
          ? <Map<String, String>>[]
          : await widget.service.wireGuardPeersByInterface(name);
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer l’interface WireGuard ?'),
              content: Text(
                '${name.isEmpty ? 'Interface' : name} possède ${peers.length} peer(s).\n\n'
                'La suppression peut couper un chemin VPN utilisé pour le management distant.',
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
      await widget.service.remove('/interface/wireguard', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('WireGuard'),
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
              label: const Text('Ajouter interface WireGuard'),
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
                          leading: CircleAvatar(
                            child: Icon(
                              disabled
                                  ? Icons.vpn_lock_outlined
                                  : Icons.vpn_key_outlined,
                            ),
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'Port ${r['listen-port'] ?? '—'}',
                              'MTU ${r['mtu'] ?? '—'}',
                              if ((r['public-key'] ?? '').isNotEmpty)
                                'Public key disponible',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => action(v, r),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'peers',
                                child: Text('Peers'),
                              ),
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
