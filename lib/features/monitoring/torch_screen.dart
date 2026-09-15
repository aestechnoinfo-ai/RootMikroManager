import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/routeros/router_session.dart';
import '../../core/routeros/routeros_streaming_service.dart';

class TorchScreen extends StatefulWidget {
  const TorchScreen({super.key});

  @override
  State<TorchScreen> createState() => _TorchScreenState();
}

class _TorchScreenState extends State<TorchScreen> {
  final streaming = RouterOsStreamingService();
  final srcAddress = TextEditingController();
  final dstAddress = TextEditingController();
  final protocol = TextEditingController();
  final port = TextEditingController();

  List<Map<String, String>> interfaces = [];
  final List<Map<String, String>> rows = [];

  String? interfaceName;
  StreamSubscription<Map<String, String>>? subscription;
  bool running = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadInterfaces();
  }

  Future<void> loadInterfaces() async {
    try {
      interfaces = await RouterSession.instance.service.interfaces();
      interfaceName = interfaces.isEmpty ? null : interfaces.first['name'];
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> start() async {
    await stop();

    final name = interfaceName;
    if (name == null) return;

    rows.clear();
    setState(() {
      running = true;
      error = null;
    });

    try {
      subscription = streaming
          .torch(
            name,
            srcAddress: srcAddress.text,
            dstAddress: dstAddress.text,
            protocol: protocol.text,
            port: port.text,
          )
          .listen(
            (row) {
              rows.insert(0, row);
              if (rows.length > 200) rows.removeLast();
              if (mounted) setState(() {});
            },
            onError: (Object e) {
              if (mounted) {
                setState(() {
                  running = false;
                  error = '$e';
                });
              }
            },
            onDone: () {
              if (mounted) setState(() => running = false);
            },
          );
    } catch (e) {
      setState(() {
        running = false;
        error = '$e';
      });
    }
  }

  Future<void> stop() async {
    await subscription?.cancel();
    subscription = null;
    await streaming.cancelActive();
    if (mounted) setState(() => running = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Torch temps réel'),
      actions: [
        IconButton(
          tooltip: running ? 'Arrêter' : 'Démarrer',
          onPressed: running ? stop : start,
          icon: Icon(
            running ? Icons.stop_circle_outlined : Icons.play_circle_outline,
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        DropdownButtonFormField<String>(
          value: interfaceName,
          decoration: const InputDecoration(labelText: 'Interface'),
          items: interfaces
              .map(
                (row) => DropdownMenuItem(
                  value: row['name'],
                  child: Text(row['name'] ?? '—'),
                ),
              )
              .toList(),
          onChanged: running
              ? null
              : (value) => setState(() => interfaceName = value),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 620;
            final fields = [
              _field(srcAddress, 'Source address'),
              _field(dstAddress, 'Destination address'),
              _field(protocol, 'Protocol'),
              _field(port, 'Port'),
            ];

            return narrow
                ? Column(
                    children: [
                      for (final f in fields) ...[f, const SizedBox(height: 8)],
                    ],
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final f in fields)
                        SizedBox(
                          width: (constraints.maxWidth - 10) / 2,
                          child: f,
                        ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: running ? stop : start,
          icon: Icon(running ? Icons.stop : Icons.bolt),
          label: Text(running ? 'Arrêter Torch' : 'Démarrer Torch'),
        ),
        if (error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          'Résultats : ${rows.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        for (final row in rows)
          Card(
            child: ListTile(
              title: Text(
                '${row['src-address'] ?? row['src-address6'] ?? '—'}'
                ' → '
                '${row['dst-address'] ?? row['dst-address6'] ?? '—'}',
              ),
              subtitle: Text(
                [
                  if ((row['protocol'] ?? '').isNotEmpty)
                    'Proto: ${row['protocol']}',
                  if ((row['src-port'] ?? '').isNotEmpty)
                    'Src: ${row['src-port']}',
                  if ((row['dst-port'] ?? '').isNotEmpty)
                    'Dst: ${row['dst-port']}',
                  if ((row['tx'] ?? '').isNotEmpty) 'TX: ${row['tx']}',
                  if ((row['rx'] ?? '').isNotEmpty) 'RX: ${row['rx']}',
                  if ((row['tx-rate'] ?? '').isNotEmpty)
                    'TX rate: ${row['tx-rate']}',
                  if ((row['rx-rate'] ?? '').isNotEmpty)
                    'RX rate: ${row['rx-rate']}',
                ].join(' • '),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _field(TextEditingController controller, String label) => TextField(
    controller: controller,
    enabled: !running,
    decoration: InputDecoration(labelText: label),
  );

  @override
  void dispose() {
    subscription?.cancel();
    streaming.close();
    srcAddress.dispose();
    dstAddress.dispose();
    protocol.dispose();
    port.dispose();
    super.dispose();
  }
}
