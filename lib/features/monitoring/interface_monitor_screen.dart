import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';
import '../../core/routeros/routeros_streaming_service.dart';

class InterfaceMonitorScreen extends StatefulWidget {
  final RouterOsService service;
  final String? initialInterface;

  const InterfaceMonitorScreen({
    super.key,
    required this.service,
    this.initialInterface,
  });

  @override
  State<InterfaceMonitorScreen> createState() => _InterfaceMonitorScreenState();
}

class _InterfaceMonitorScreenState extends State<InterfaceMonitorScreen> {
  final streaming = RouterOsStreamingService();

  List<Map<String, String>> interfaces = [];
  String? selectedName;
  Map<String, String> traffic = {};

  final List<double> rxHistory = [];
  final List<double> txHistory = [];

  StreamSubscription<Map<String, String>>? subscription;
  Timer? fallbackTimer;

  bool loading = true;
  bool streamingActive = false;
  bool fallbackPolling = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      interfaces = await widget.service.interfaces();
      final requested = widget.initialInterface;
      selectedName ??=
          requested != null && interfaces.any((e) => e['name'] == requested)
          ? requested
          : interfaces.isNotEmpty
          ? interfaces.first['name']
          : null;

      if (selectedName != null) {
        await startMonitoring();
      }
    } catch (e) {
      error = '$e';
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> startMonitoring() async {
    await stopMonitoring();

    final name = selectedName;
    if (name == null) return;

    setState(() {
      error = null;
      traffic = {};
      rxHistory.clear();
      txHistory.clear();
    });

    try {
      final stream = streaming.monitorInterface(name);

      subscription = stream.listen(
        onTraffic,
        onError: (Object e) {
          if (mounted) {
            setState(() {
              error = 'Streaming indisponible ($e). Basculement en polling.';
              streamingActive = false;
            });
          }
          startFallback();
        },
        onDone: () {
          if (mounted && !fallbackPolling) {
            setState(() => streamingActive = false);
          }
        },
      );

      if (mounted) setState(() => streamingActive = true);
    } catch (e) {
      error = 'Streaming indisponible ($e). Basculement en polling.';
      await startFallback();
    }
  }

  void onTraffic(Map<String, String> row) {
    final rx = _rate(row['rx-bits-per-second']);
    final tx = _rate(row['tx-bits-per-second']);

    _append(rxHistory, rx);
    _append(txHistory, tx);

    if (mounted) {
      setState(() {
        traffic = row;
        streamingActive = true;
        fallbackPolling = false;
      });
    }
  }

  Future<void> startFallback() async {
    fallbackTimer?.cancel();
    fallbackPolling = true;
    await pollOnce();

    fallbackTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => pollOnce(),
    );

    if (mounted) setState(() {});
  }

  Future<void> pollOnce() async {
    final name = selectedName;
    if (name == null) return;

    try {
      final row = await widget.service.interfaceTrafficOnce(name);
      final rx = _rate(row['rx-bits-per-second']);
      final tx = _rate(row['tx-bits-per-second']);
      _append(rxHistory, rx);
      _append(txHistory, tx);

      if (mounted) {
        setState(() => traffic = row);
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> stopMonitoring() async {
    fallbackTimer?.cancel();
    fallbackTimer = null;
    fallbackPolling = false;

    await subscription?.cancel();
    subscription = null;

    await streaming.cancelActive();

    if (mounted) setState(() => streamingActive = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Traffic temps réel'),
      actions: [
        IconButton(
          tooltip: streamingActive || fallbackPolling ? 'Arrêter' : 'Démarrer',
          onPressed: () {
            if (streamingActive || fallbackPolling) {
              stopMonitoring();
            } else {
              startMonitoring();
            }
          },
          icon: Icon(
            streamingActive || fallbackPolling
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline,
          ),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: const EdgeInsets.all(12),
              children: [
                DropdownButtonFormField<String>(
                  value: selectedName,
                  decoration: const InputDecoration(labelText: 'Interface'),
                  items: interfaces
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item['name'],
                          child: Text(item['name'] ?? '—'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    setState(() => selectedName = value);
                    await startMonitoring();
                  },
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: Icon(
                      streamingActive
                          ? Icons.stream
                          : fallbackPolling
                          ? Icons.sync
                          : Icons.pause_circle_outline,
                    ),
                    title: Text(
                      streamingActive
                          ? 'Streaming RouterOS'
                          : fallbackPolling
                          ? 'Fallback polling 2 s'
                          : 'Monitoring arrêté',
                    ),
                    subtitle: const Text(
                      'Le streaming utilise router_os_client avec tag '
                      'et annulation explicite.',
                    ),
                  ),
                ),
                if (error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(error!),
                    ),
                  ),
                const SizedBox(height: 10),
                _ResponsiveMetrics(traffic: traffic),
                const SizedBox(height: 12),
                SizedBox(
                  height: constraints.maxWidth < 500 ? 180 : 230,
                  child: _TrafficChart(rx: rxHistory, tx: txHistory),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: fallbackPolling ? pollOnce : startMonitoring,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    fallbackPolling
                        ? 'Actualiser maintenant'
                        : 'Relancer le streaming',
                  ),
                ),
              ],
            ),
          ),
  );

  double _rate(String? value) {
    if (value == null || value.isEmpty) return 0;
    final normalized = value.toLowerCase().replaceAll('bps', '').trim();

    double multiplier = 1;
    var numeric = normalized;

    if (normalized.endsWith('k')) {
      multiplier = 1000;
      numeric = normalized.substring(0, normalized.length - 1);
    } else if (normalized.endsWith('m')) {
      multiplier = 1000000;
      numeric = normalized.substring(0, normalized.length - 1);
    } else if (normalized.endsWith('g')) {
      multiplier = 1000000000;
      numeric = normalized.substring(0, normalized.length - 1);
    }

    return (double.tryParse(numeric) ?? 0) * multiplier;
  }

  void _append(List<double> values, double value) {
    values.add(value);
    if (values.length > 60) values.removeAt(0);
  }

  @override
  void dispose() {
    fallbackTimer?.cancel();
    subscription?.cancel();
    streaming.close();
    super.dispose();
  }
}

class _ResponsiveMetrics extends StatelessWidget {
  final Map<String, String> traffic;

  const _ResponsiveMetrics({required this.traffic});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 900
          ? 4
          : width >= 600
          ? 3
          : width >= 360
          ? 2
          : 1;
      final itemWidth = (width - ((columns - 1) * 10)) / columns;

      final metrics = <(String, String)>[
        ('RX bits/s', traffic['rx-bits-per-second'] ?? '0'),
        ('TX bits/s', traffic['tx-bits-per-second'] ?? '0'),
        ('RX packets/s', traffic['rx-packets-per-second'] ?? '0'),
        ('TX packets/s', traffic['tx-packets-per-second'] ?? '0'),
        ('FP RX', traffic['fp-rx-bits-per-second'] ?? '0'),
        ('FP TX', traffic['fp-tx-bits-per-second'] ?? '0'),
        ('TX drops/s', traffic['tx-queue-drops-per-second'] ?? '0'),
      ];

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: itemWidth,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Text(metric.$1, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        metric.$2,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _TrafficChart extends StatelessWidget {
  final List<double> rx;
  final List<double> tx;

  const _TrafficChart({required this.rx, required this.tx});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: _TrafficPainter(
          List<double>.of(rx),
          List<double>.of(tx),
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _TrafficPainter extends CustomPainter {
  final List<double> rx;
  final List<double> tx;
  final Color rxColor;
  final Color txColor;

  _TrafficPainter(this.rx, this.tx, this.rxColor, this.txColor);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = [...rx, ...tx, 1.0].reduce((a, b) => a > b ? a : b);

    final rxPaint = Paint()
      ..color = rxColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final txPaint = Paint()
      ..color = txColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    _drawSeries(canvas, size, rx, maxValue, rxPaint);
    _drawSeries(canvas, size, tx, maxValue, txPaint);
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> data,
    double maxValue,
    Paint paint,
  ) {
    if (data.length < 2) return;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y =
          size.height - (size.height * (data[i] / maxValue).clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrafficPainter oldDelegate) {
    if (oldDelegate.rxColor != rxColor ||
        oldDelegate.txColor != txColor ||
        oldDelegate.rx.length != rx.length ||
        oldDelegate.tx.length != tx.length)
      return true;
    if (rx.isNotEmpty &&
        oldDelegate.rx.isNotEmpty &&
        oldDelegate.rx.last != rx.last)
      return true;
    if (tx.isNotEmpty &&
        oldDelegate.tx.isNotEmpty &&
        oldDelegate.tx.last != tx.last)
      return true;
    return false;
  }
}
