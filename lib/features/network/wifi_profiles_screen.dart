import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'wifi_profile_kind.dart';

class WifiProfilesScreen extends StatefulWidget {
  final RouterOsService service;
  const WifiProfilesScreen({super.key, required this.service});
  @override
  State<WifiProfilesScreen> createState() => _S();
}

class _S extends State<WifiProfilesScreen> {
  bool loading = true;
  Map<WifiProfileKind, List<Map<String, String>>> rows = {};
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final r = await Future.wait([
      widget.service.wifiConfigurations(),
      widget.service.wifiChannels(),
      widget.service.wifiSecurityProfilesModern(),
      widget.service.wifiDatapaths(),
    ]);
    rows = {
      WifiProfileKind.configuration: r[0],
      WifiProfileKind.channel: r[1],
      WifiProfileKind.security: r[2],
      WifiProfileKind.datapath: r[3],
    };
    if (mounted) setState(() => loading = false);
  }

  bool secret(String k) {
    final x = k.toLowerCase();
    return x.contains('passphrase') ||
        x.contains('password') ||
        x.contains('pre-shared') ||
        x.contains('private-key');
  }

  Future<void> edit(WifiProfileKind k, [Map<String, String>? row]) async {
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.wifiProfileEdit,
      extra: WifiProfilePayload(kind: k, row: row),
    );
    if (x == true) await load();
  }

  Future<void> removeProfile(WifiProfileKind k, Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Supprimer ${r['name'] ?? k.label} ?'),
            content: const Text(
              'Vérifiez d’abord que ce profil n’est pas référencé par une configuration, une interface ou une règle de provisioning.',
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
      await widget.service.remove(k.path, id);
      await load();
    }
  }

  Widget section(WifiProfileKind k, IconData icon) {
    final a = rows[k] ?? [];
    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text('${k.label} (${a.length})'),
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: Text('Ajouter ${k.label}'),
            onTap: () => edit(k),
          ),
          for (final r in a)
            ListTile(
              onTap: () => edit(k, r),
              title: Text(r['name'] ?? r['.id'] ?? '—'),
              subtitle: Text(
                r.entries
                    .where(
                      (e) =>
                          e.key != '.id' &&
                          e.key != 'name' &&
                          e.value.isNotEmpty &&
                          !secret(e.key),
                    )
                    .take(5)
                    .map((e) => '${e.key}: ${e.value}')
                    .join(' • '),
              ),
              trailing: IconButton(
                onPressed: () => removeProfile(k, r),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Profils WiFi moderne'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              section(WifiProfileKind.configuration, Icons.tune),
              section(WifiProfileKind.channel, Icons.cell_tower_outlined),
              section(WifiProfileKind.security, Icons.security_outlined),
              section(WifiProfileKind.datapath, Icons.alt_route_outlined),
            ],
          ),
  );
}
