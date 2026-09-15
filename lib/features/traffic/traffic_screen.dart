import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/routeros/router_session.dart';

class TrafficScreen extends StatefulWidget {
  const TrafficScreen({super.key});
  @override
  State<TrafficScreen> createState() => _TrafficScreenState();
}

class _TrafficScreenState extends State<TrafficScreen> {
  Timer? t;
  List<Map<String, String>> data = [];
  String error = '';
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _load();
    t = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!RouterSession.instance.connected) {
      if (mounted)
        setState(() => error = 'Connectez-vous d’abord à un routeur.');
      return;
    }
    if (loading) return;
    loading = true;
    try {
      final x = await RouterSession.instance.service.interfaces();
      if (mounted)
        setState(() {
          data = x;
          error = '';
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      loading = false;
    }
  }

  @override
  Widget build(c) => Scaffold(
    appBar: AppBar(title: const Text('Traffic en temps réel')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Actualisation automatique toutes les 3 secondes',
            style: Theme.of(c).textTheme.bodyMedium,
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(error),
            ),
          ...data.map(
            (x) => Card(
              child: ListTile(
                leading: const Icon(Icons.network_check),
                title: Text(x['name'] ?? 'Interface'),
                subtitle: Text(
                  'RX: ${x['rx-byte'] ?? '—'} octets   •   TX: ${x['tx-byte'] ?? '—'} octets',
                ),
                trailing: Text(x['running'] == 'true' ? 'ON' : 'OFF'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
