import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'rootmikromanager_profile_metadata.dart';

class HotspotExpirationIntegrityScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotExpirationIntegrityScreen({super.key, required this.service});
  @override
  State<HotspotExpirationIntegrityScreen> createState() => _S();
}

class _S extends State<HotspotExpirationIntegrityScreen> {
  bool loading = true;
  List<String> issues = [];
  int expired = 0, cookies = 0, active = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.hotspotProfiles(),
      widget.service.hotspotUsers(),
      widget.service.hotspotCookies(),
      widget.service.activeUsers(),
      widget.service.schedulers(),
    ]);
    final profiles = x[0], users = x[1], cks = x[2], act = x[3], sched = x[4];
    issues = [];
    final schedNames = sched.map((e) => e['name'] ?? '').toSet();
    final cookieUsers = cks.map((e) => e['user'] ?? '').toSet(),
        activeUsers = act.map((e) => e['user'] ?? '').toSet();
    expired = 0;
    cookies = 0;
    active = 0;
    for (final u in users.where((e) => (e['limit-uptime'] ?? '') == '1s')) {
      expired++;
      final n = u['name'] ?? '';
      if (cookieUsers.contains(n)) {
        cookies++;
        issues.add('$n : ticket expiré avec cookie encore présent.');
      }
      if (activeUsers.contains(n)) {
        active++;
        issues.add('$n : ticket expiré avec session active encore présente.');
      }
    }
    for (final p in profiles) {
      final meta = RootMikroManagerProfileMetadata.fromProfile(p);
      final name = p['name'] ?? '';
      if (meta.validity.isNotEmpty && !schedNames.contains(name))
        issues.add(
          '$name : validité ${meta.validity} détectée mais aucun scheduler de surveillance portant ce nom.',
        );
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Audit expiration Hotspot'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Tickets marqués expirés'),
                  trailing: Text('$expired'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Cookies encore associés'),
                  trailing: Text('$cookies'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Sessions actives associées'),
                  trailing: Text('$active'),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Un ticket expiré ne doit pas conserver de cookie ni de session active : le client doit pouvoir retrouver la page Login du portail captif.',
                  ),
                ),
              ),
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucune incohérence simple détectée.'),
                  ),
                ),
              for (final x in issues)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(x),
                  ),
                ),
            ],
          ),
  );
}
