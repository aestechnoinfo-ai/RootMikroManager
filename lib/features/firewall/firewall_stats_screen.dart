import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class FirewallStatsScreen extends StatefulWidget {
  final RouterOsService service;
  const FirewallStatsScreen({super.key, required this.service});

  @override
  State<FirewallStatsScreen> createState() => _FirewallStatsScreenState();
}

class _FirewallStatsScreenState extends State<FirewallStatsScreen> {
  bool loading = true;
  Map<String, List<Map<String, String>>> data = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final paths = {
      'Filter': '/ip/firewall/filter',
      'NAT': '/ip/firewall/nat',
      'Mangle': '/ip/firewall/mangle',
      'RAW': '/ip/firewall/raw',
      'Address Lists': '/ip/firewall/address-list',
    };
    final result = <String, List<Map<String, String>>>{};
    for (final e in paths.entries) {
      try {
        result[e.key] = await widget.service.client.print(e.value);
      } catch (_) {
        result[e.key] = [];
      }
    }
    data = result;
    if (mounted) setState(() => loading = false);
  }

  bool yes(Map<String, String> row, String key) =>
      row[key] == 'yes' || row[key] == 'true';

  int active(List<Map<String, String>> rows) =>
      rows.where((r) => !yes(r, 'disabled')).length;

  int fasttrack(List<Map<String, String>> rows) =>
      rows.where((r) => r['action'] == 'fasttrack-connection').length;

  int invalid(List<Map<String, String>> rows) =>
      rows.where((r) => yes(r, 'invalid')).length;

  int dynamicOrDummy(List<Map<String, String>> rows) =>
      rows.where((r) => yes(r, 'dynamic') || yes(r, 'dummy')).length;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Firewall — statistiques'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final e in data.entries)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.security_outlined),
                      title: Text(e.key),
                      subtitle: Text(
                        [
                          '${active(e.value)} active(s) sur ${e.value.length}',
                          if (e.key == 'Filter' && fasttrack(e.value) > 0)
                            '${fasttrack(e.value)} FastTrack',
                          if (invalid(e.value) > 0)
                            '${invalid(e.value)} invalide(s)',
                          if (dynamicOrDummy(e.value) > 0)
                            '${dynamicOrDummy(e.value)} dynamique(s)/dummy',
                        ].join(' • '),
                      ),
                      trailing: Text(
                        '${e.value.length}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}
