import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RoutingPolicySafetyScreen extends StatefulWidget {
  final RouterOsService service;
  const RoutingPolicySafetyScreen({super.key, required this.service});
  @override
  State<RoutingPolicySafetyScreen> createState() => _State();
}

class _State extends State<RoutingPolicySafetyScreen> {
  bool loading = true;
  List<Map<String, String>> tables = [],
      rules = [],
      routes4 = [],
      routes6 = [],
      addresses6 = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await Future.wait([
      widget.service.routingTablesAdvanced(),
      widget.service.routingRules(),
      widget.service.ipRoutes(),
      widget.service.ipv6Routes(),
      widget.service.ipv6Addresses(),
    ]);
    tables = x[0];
    rules = x[1];
    routes4 = x[2];
    routes6 = x[3];
    addresses6 = x[4];
    if (mounted) setState(() => loading = false);
  }

  List<String> warnings() {
    final out = <String>[];
    final names = tables.map((e) => e['name']).whereType<String>().toSet();
    for (final r in rules) {
      final a = r['action'] ?? 'lookup', t = r['table'] ?? '';
      if (a.startsWith('lookup') && t.isNotEmpty && !names.contains(t))
        out.add('Routing Rule vers table absente : $t.');
      if (a == 'lookup-only-in-table' &&
          (r['src-address'] ?? '').isEmpty &&
          (r['dst-address'] ?? '').isEmpty &&
          (r['interface'] ?? '').isEmpty)
        out.add(
          'lookup-only-in-table sans critère : risque de détourner presque tout le trafic.',
        );
      if ((a == 'drop' || a == 'unreachable') &&
          (r['src-address'] ?? '').isEmpty &&
          (r['dst-address'] ?? '').isEmpty &&
          (r['interface'] ?? '').isEmpty)
        out.add('$a sans critère : risque de blocage global.');
    }
    for (final t in names.where((e) => e != 'main')) {
      final has4 = routes4.any((r) => r['routing-table'] == t);
      final has6 = routes6.any((r) => r['routing-table'] == t);
      if (!has4 && !has6) out.add('Table $t sans route IPv4/IPv6 détectée.');
    }
    if (routes6.any(
      (r) => r['dst-address'] == '::/0' && r['disabled'] != 'yes',
    ))
      out.add(
        'Une route IPv6 par défaut ::/0 est active : vérifiez le chemin de management.',
      );
    if (addresses6.any(
      (a) => a['advertise'] == 'yes' && !(a['address'] ?? '').endsWith('/64'),
    ))
      out.add(
        'Une adresse IPv6 advertise=yes n’utilise pas /64 ; vérifiez la stratégie SLAAC.',
      );
    return out;
  }

  @override
  Widget build(BuildContext c) {
    final x = warnings();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité Routing Policy & IPv6'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Tables de routage'),
                    trailing: Text('${tables.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Routing Rules'),
                    trailing: Text('${rules.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Routes IPv4'),
                    trailing: Text('${routes4.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Routes IPv6'),
                    trailing: Text('${routes6.length}'),
                  ),
                ),
                if (x.isEmpty)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Aucun risque simple détecté'),
                    ),
                  ),
                for (final s in x)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(s),
                    ),
                  ),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Cet audit est volontairement conservatif : il signale des configurations potentiellement dangereuses mais ne remplace pas l’analyse complète de la topologie.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
