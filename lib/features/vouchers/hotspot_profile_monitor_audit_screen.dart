import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../hotspot/hotspot_profile_config.dart';

class HotspotProfileMonitorAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotProfileMonitorAuditScreen({super.key, required this.service});
  @override
  State<HotspotProfileMonitorAuditScreen> createState() => _State();
}

class _State extends State<HotspotProfileMonitorAuditScreen> {
  bool loading = true;
  List<Map<String, String>> profiles = [], schedulers = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final x = await Future.wait([
      widget.service.hotspotProfiles(),
      widget.service.schedulers(),
    ]);
    profiles = x[0];
    schedulers = x[1];
    if (mounted) setState(() => loading = false);
  }

  bool hasMonitor(String name) =>
      schedulers.any((s) => (s['name'] ?? '') == name);
  Future<void> repair(Map<String, String> row) async {
    final config = HotspotProfileConfig.fromRouterOs(row);
    await widget.service.saveRootMikroManagerHotspotProfile(config);
    await load();
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Surveillance de ${config.name} resynchronisée.'),
        ),
      );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Moniteurs de validité'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Un profil avec mode d’expiration doit disposer de son scheduler de surveillance. La réparation resauvegarde le profil sans toucher aux tickets déjà créés.',
                  ),
                ),
              ),
              for (final row in profiles)
                Builder(
                  builder: (context) {
                    final cfg = HotspotProfileConfig.fromRouterOs(row);
                    final required =
                        cfg.expirationMode != HotspotExpirationMode.none;
                    final ok = !required || hasMonitor(cfg.name);
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          ok
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                        ),
                        title: Text(cfg.name),
                        subtitle: Text(
                          required
                              ? '${cfg.expirationMode.label} • validité ${cfg.validity.isEmpty ? '—' : cfg.validity} • monitor ${hasMonitor(cfg.name) ? 'actif' : 'absent'}'
                              : 'Expiration désactivée',
                        ),
                        trailing: !ok
                            ? TextButton(
                                onPressed: () => repair(row),
                                child: const Text('Réparer'),
                              )
                            : null,
                      ),
                    );
                  },
                ),
            ],
          ),
  );
}
