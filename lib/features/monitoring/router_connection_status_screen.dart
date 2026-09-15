import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/routeros/router_session.dart';

class RouterConnectionStatusScreen extends StatefulWidget {
  const RouterConnectionStatusScreen({super.key});
  @override
  State<RouterConnectionStatusScreen> createState() =>
      _RouterConnectionStatusScreenState();
}

class _RouterConnectionStatusScreenState
    extends State<RouterConnectionStatusScreen> {
  bool testing = false;
  bool? reachable;
  Duration? latency;
  String? detail;

  Future<void> runTest() async {
    final router = RouterSession.instance.activeRouter;
    if (router == null) {
      setState(() {
        reachable = false;
        detail = 'Aucun routeur actif.';
      });
      return;
    }
    setState(() {
      testing = true;
      reachable = null;
      latency = null;
      detail = null;
    });
    final watch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        router.host,
        router.port,
        timeout: const Duration(seconds: 5),
      );
      watch.stop();
      if (mounted)
        setState(() {
          reachable = true;
          latency = watch.elapsed;
          detail = 'Connexion TCP ouverte sur ${router.host}:${router.port}.';
        });
    } on SocketException catch (e) {
      watch.stop();
      if (mounted)
        setState(() {
          reachable = false;
          latency = watch.elapsed;
          detail =
              'Impossible d’ouvrir ${router.host}:${router.port}. Vérifie API/API-SSL, firewall et VPN. $e';
        });
    } on TimeoutException {
      watch.stop();
      if (mounted)
        setState(() {
          reachable = false;
          latency = watch.elapsed;
          detail =
              'Timeout après 5 secondes sur ${router.host}:${router.port}.';
        });
    } finally {
      socket?.destroy();
      if (mounted) setState(() => testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = RouterSession.instance.activeRouter;
    return Scaffold(
      appBar: AppBar(title: const Text('État connexion RouterOS')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    router?.name ?? 'Aucun routeur',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _line('Hôte', router?.host ?? '—'),
                  _line('Port API', router?.port.toString() ?? '—'),
                  _line(
                    'Transport',
                    router?.port == 8729 ? 'API-SSL' : 'RouterOS API',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Icon(
                    reachable == true
                        ? Icons.check_circle_outline
                        : reachable == false
                        ? Icons.error_outline
                        : Icons.network_check,
                    size: 54,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    testing
                        ? 'Test en cours…'
                        : reachable == true
                        ? 'Port API accessible'
                        : reachable == false
                        ? 'Port API inaccessible'
                        : 'Test non lancé',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (latency != null) ...[
                    const SizedBox(height: 6),
                    Text('Ouverture TCP : ${latency!.inMilliseconds} ms'),
                  ],
                  if (detail != null) ...[
                    const SizedBox(height: 8),
                    Text(detail!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: testing ? null : runTest,
                    icon: const Icon(Icons.network_ping),
                    label: const Text('Tester le port API'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Compatibilité RootMikroManager : status/ping-test.php utilise fsockopen() sur le port API et non un ping ICMP. Ce test reproduit cette vérification en TCP.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
