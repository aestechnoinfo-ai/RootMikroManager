import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'queue_monitor_settings.dart';

class QueueMonitorScreen extends StatefulWidget {
  final RouterOsService service;
  const QueueMonitorScreen({super.key, required this.service});

  @override
  State<QueueMonitorScreen> createState() => _QueueMonitorScreenState();
}

class _QueueMonitorScreenState extends State<QueueMonitorScreen>
    with WidgetsBindingObserver {
  final search = TextEditingController();
  bool loading = true;
  bool refreshing = false;
  int section = 0;
  List<Map<String, String>> rows = [];
  QueueMonitorSettings settings = const QueueMonitorSettings();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    search.addListener(() => setState(() {}));
    bootstrap();
  }

  Future<void> bootstrap() async {
    settings = await QueueMonitorSettings.load();
    await load();
    configureTimer();
  }

  void configureTimer() {
    timer?.cancel();
    if (!settings.autoRefresh) return;
    timer = Timer.periodic(
      Duration(seconds: settings.refreshSeconds),
      (_) => load(background: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      load(background: true);
      configureTimer();
    } else {
      timer?.cancel();
    }
  }

  Future<void> load({bool background = false}) async {
    if (refreshing) return;
    refreshing = true;
    if (!background && mounted) setState(() => loading = true);
    try {
      rows = section == 0
          ? await widget.service.simpleQueues()
          : await widget.service.queueTree();
    } finally {
      refreshing = false;
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> settingsPage() async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.queueMonitorSettings,
    );
    if (changed == true) {
      settings = await QueueMonitorSettings.load();
      configureTimer();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Monitoring Queues'),
      actions: [
        IconButton(onPressed: settingsPage, icon: const Icon(Icons.tune)),
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Simple'),
                  icon: Icon(Icons.speed),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Tree'),
                  icon: Icon(Icons.account_tree_outlined),
                ),
              ],
              selected: {section},
              onSelectionChanged: (v) async {
                section = v.first;
                await load();
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Nom, cible, parent, mark…',
            ),
          ),
        ),
        if (settings.autoRefresh)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Auto ${settings.refreshSeconds}s',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final r = visible[i];
                      return Card(
                        child: ListTile(
                          onTap: () => AppRouter.pushNamed(
                            context,
                            AppRoutes.queueDetail,
                            extra: QueueDetailPayload(
                              title: r['name'] ?? 'Queue',
                              row: r,
                            ),
                          ),
                          leading: const CircleAvatar(
                            child: Icon(Icons.monitor_heart_outlined),
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              if ((r['rate'] ?? '').isNotEmpty)
                                'Rate ${r['rate']}',
                              if ((r['max-limit'] ?? '').isNotEmpty)
                                'Max ${r['max-limit']}',
                              if ((r['queued-bytes'] ?? '').isNotEmpty)
                                'Queued ${r['queued-bytes']}',
                              if (settings.showBytes &&
                                  (r['bytes'] ?? '').isNotEmpty)
                                'Bytes ${r['bytes']}',
                              if (settings.showPackets &&
                                  (r['packets'] ?? '').isNotEmpty)
                                'Packets ${r['packets']}',
                            ].join(' • '),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    search.dispose();
    super.dispose();
  }
}
