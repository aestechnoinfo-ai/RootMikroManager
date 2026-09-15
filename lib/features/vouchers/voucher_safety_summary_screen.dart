import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VoucherSafetySummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherSafetySummaryScreen({super.key, required this.service});
  @override
  State<VoucherSafetySummaryScreen> createState() => _S();
}

class _S extends State<VoucherSafetySummaryScreen> {
  bool loading = true;
  List<Map<String, String>> users = [],
      profiles = [],
      cookies = [],
      active = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Future.wait([
      widget.service.hotspotUsers(),
      widget.service.hotspotProfiles(),
      widget.service.hotspotCookies(),
      widget.service.activeUsers(),
    ]);
    users = r[0];
    profiles = r[1];
    cookies = r[2];
    active = r[3];
    if (mounted) setState(() => loading = false);
  }

  List<String> warnings() {
    final out = <String>[];
    final p = profiles.map((e) => e['name']).whereType<String>().toSet();
    final names = users.map((e) => e['name']).whereType<String>().toSet();
    final orphan = users
        .where((u) => !p.contains(u['profile'] ?? 'default'))
        .length;
    if (orphan > 0) out.add('$orphan ticket(s) référencent un profil absent.');
    final stale = cookies.where((c) => !names.contains(c['user'])).length;
    if (stale > 0)
      out.add('$stale cookie(s) ne correspondent à aucun ticket actuel.');
    final activeOrphan = active.where((a) => !names.contains(a['user'])).length;
    if (activeOrphan > 0)
      out.add('$activeOrphan session(s) actives n’ont plus de ticket local.');
    return out;
  }

  @override
  Widget build(BuildContext c) {
    final x = warnings();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité vouchers'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Tickets'),
                    trailing: Text('${users.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Profils Hotspot'),
                    trailing: Text('${profiles.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Cookies'),
                    trailing: Text('${cookies.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Sessions actives'),
                    trailing: Text('${active.length}'),
                  ),
                ),
                if (x.isEmpty)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Aucune incohérence simple détectée'),
                    ),
                  ),
                for (final s in x)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(s),
                    ),
                  ),
              ],
            ),
    );
  }
}
