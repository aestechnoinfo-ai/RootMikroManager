import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class WireGuardPeersScreen extends StatefulWidget {
  final RouterOsService service;
  const WireGuardPeersScreen({super.key, required this.service});
  @override
  State<WireGuardPeersScreen> createState() => _State();
}

class _State extends State<WireGuardPeersScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.wireGuardPeers();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? r]) async {
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.wireGuardPeerEditNetwork,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> toggle(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    await widget.service.set('/interface/wireguard/peers', id, {
      'disabled': r['disabled'] == 'yes' ? 'no' : 'yes',
    });
    await load();
  }

  Future<void> removePeer(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer ce peer WireGuard ?'),
            content: Text(
              '${r['interface'] ?? '—'} • ${r['allowed-address'] ?? '—'}',
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
      await widget.service.remove('/interface/wireguard/peers', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('WireGuard Peers'),
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
              label: const Text('Ajouter un peer'),
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
                          onTap: () => edit(r),
                          leading: Icon(
                            r['disabled'] == 'yes'
                                ? Icons.pause_circle_outline
                                : Icons.vpn_lock_outlined,
                          ),
                          title: Text(r['name'] ?? r['comment'] ?? 'Peer'),
                          subtitle: Text(
                            [
                              'if ${r['interface'] ?? '—'}',
                              'allowed ${r['allowed-address'] ?? '—'}',
                              if ((r['current-endpoint-address'] ?? '')
                                  .isNotEmpty)
                                'endpoint ${r['current-endpoint-address']}:${r['current-endpoint-port'] ?? ''}',
                              'handshake ${r['last-handshake'] ?? '—'}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'toggle') toggle(r);
                              if (v == 'delete') removePeer(r);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  r['disabled'] == 'yes'
                                      ? 'Activer'
                                      : 'Désactiver',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                            ],
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
