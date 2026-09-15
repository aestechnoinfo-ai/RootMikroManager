import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class RoutingPolicySummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const RoutingPolicySummaryScreen({super.key, required this.service});
  @override
  State<RoutingPolicySummaryScreen> createState() => _S();
}

class _S extends State<RoutingPolicySummaryScreen> {
  bool loading = true;
  List<int> n = [0, 0, 0, 0, 0];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Future.wait([
      widget.service.routingTablesAdvanced(),
      widget.service.routingRules(),
      widget.service.ipVrfs(),
      widget.service.ipv6Routes(),
      widget.service.ipv6Neighbors(),
    ]);
    n = List.generate(5, (i) => r[i].length);
    if (mounted) setState(() => loading = false);
  }

  Widget c(String t, int v) => Card(
    child: ListTile(title: Text(t), trailing: Text('$v')),
  );
  @override
  Widget build(BuildContext x) => Scaffold(
    appBar: AppBar(title: const Text('Résumé routage avancé')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              c('Tables de routage', n[0]),
              c('Policy rules', n[1]),
              c('VRF', n[2]),
              c('Routes IPv6', n[3]),
              c('Neighbors IPv6', n[4]),
            ],
          ),
  );
}
