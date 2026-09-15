import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class WifiAclSafetyScreen extends StatefulWidget {
  final RouterOsService service;
  const WifiAclSafetyScreen({super.key, required this.service});
  @override
  State<WifiAclSafetyScreen> createState() => _S();
}

class _S extends State<WifiAclSafetyScreen> {
  bool loading = true;
  List<Map<String, String>> modern = [], legacy = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await Future.wait([
      widget.service.wifiAccessList('modern'),
      widget.service.wifiAccessList('legacy'),
    ]);
    modern = x[0];
    legacy = x[1];
    if (mounted) setState(() => loading = false);
  }

  List<String> analyze(List<Map<String, String>> a, bool modern) {
    final o = <String>[];
    for (int i = 0; i < a.length; i++) {
      final r = a[i];
      if (r['disabled'] == 'yes') continue;
      final mac = r['mac-address'] ?? '';
      final iface = r['interface'] ?? '';
      final signal = r['signal-range'] ?? '';
      final reject = modern
          ? r['action'] == 'reject'
          : r['authentication'] == 'no';
      if (reject && mac.isEmpty && iface.isEmpty && signal.isEmpty)
        o.add(
          'Règle ${i + 1} : rejet très général ; les règles suivantes peuvent ne jamais être atteintes.',
        );
      final vlan = int.tryParse(r['vlan-id'] ?? '');
      if (vlan != null && (vlan < 1 || vlan > 4094))
        o.add('Règle ${i + 1} : VLAN ID hors plage.');
    }
    return o;
  }

  @override
  Widget build(BuildContext c) {
    final m = analyze(modern, true), l = analyze(legacy, false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Access Lists'),
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
                      'Les Access Lists sont ordonnées. L’audit cherche surtout les rejets généraux placés trop tôt et les VLAN incohérents.',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('WiFi moderne'),
                    trailing: Text('${modern.length} règle(s)'),
                  ),
                ),
                for (final x in m)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(x),
                    ),
                  ),
                Card(
                  child: ListTile(
                    title: const Text('Wireless legacy'),
                    trailing: Text('${legacy.length} règle(s)'),
                  ),
                ),
                for (final x in l)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(x),
                    ),
                  ),
                if (m.isEmpty && l.isEmpty)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Aucun risque simple détecté'),
                    ),
                  ),
              ],
            ),
    );
  }
}
