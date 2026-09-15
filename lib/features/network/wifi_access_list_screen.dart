import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'wifi_config_backend.dart';

class WifiAccessListScreen extends StatefulWidget {
  final RouterOsService service;
  final WifiConfigBackend backend;
  const WifiAccessListScreen({
    super.key,
    required this.service,
    required this.backend,
  });
  @override
  State<WifiAccessListScreen> createState() => _S();
}

class _S extends State<WifiAccessListScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.wifiAccessList(widget.backend.name);
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? r]) async {
    final c = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.wifiAccessRuleEdit,
      extra: WifiAccessRulePayload(backend: widget.backend, row: r),
    );
    if (c == true) await load();
  }

  Future<void> act(String a, Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    if (a == 'edit') return edit(r);
    if (a == 'toggle') {
      final off = r['disabled'] == 'yes' || r['disabled'] == 'true';
      if (off)
        await widget.service.enable(widget.backend.accessListPath, id);
      else
        await widget.service.disable(widget.backend.accessListPath, id);
    }
    if (a == 'delete') {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer cette règle Wi‑Fi ?'),
              content: const Text(
                'Les Access Lists sont évaluées dans l’ordre. La suppression '
                'peut modifier immédiatement l’accès des clients.',
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
      await widget.service.remove(widget.backend.accessListPath, id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.backend.label} • Access List'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Les règles sont ordonnées : une règle générale placée avant une règle spécifique peut la rendre inopérante.',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une règle'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    final modern = widget.backend == WifiConfigBackend.modern;
                    final a = modern
                        ? (r['action'] ?? 'accept')
                        : ((r['authentication'] == 'no') ? 'reject' : 'accept');
                    return Card(
                      child: ListTile(
                        onTap: () => edit(r),
                        leading: Icon(
                          a == 'reject' ? Icons.block : Icons.security_outlined,
                        ),
                        title: Text(
                          r['mac-address'] ??
                              r['ssid-regexp'] ??
                              'Règle générale',
                        ),
                        subtitle: Text(
                          [
                            a,
                            if ((r['interface'] ?? '').isNotEmpty)
                              r['interface']!,
                            if ((r['signal-range'] ?? '').isNotEmpty)
                              r['signal-range']!,
                            if ((r['vlan-id'] ?? '').isNotEmpty)
                              'VLAN ${r['vlan-id']}',
                          ].join(' • '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) => act(v, r),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Modifier'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text('Activer / désactiver'),
                            ),
                            PopupMenuItem(
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
      ],
    ),
  );
}
