import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/routeros/routeros_service.dart';
import 'ppp_monitor_settings.dart';

class PppActiveScreen extends StatefulWidget {
  final RouterOsService service;
  const PppActiveScreen({super.key, required this.service});
  @override
  State<PppActiveScreen> createState() => _PppActiveScreenState();
}

class _PppActiveScreenState extends State<PppActiveScreen>
    with WidgetsBindingObserver {
  final search = TextEditingController();
  List<Map<String, String>> rows = [];
  PppMonitorSettings settings = const PppMonitorSettings();
  Timer? timer;
  bool loading = true, refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    search.addListener(() => setState(() {}));
    bootstrap();
  }

  Future<void> bootstrap() async {
    settings = await PppMonitorSettings.load();
    await load();
    configureTimer();
  }

  void configureTimer() {
    timer?.cancel();
    if (settings.autoRefresh) {
      timer = Timer.periodic(
        Duration(seconds: settings.refreshSeconds),
        (_) => load(background: true),
      );
    }
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
      rows = await widget.service.pppActive();
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

  Future<void> disconnect(Map<String, String> row) async {
    var ok = true;
    if (settings.confirmDisconnect) {
      ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Déconnecter la session PPP ?'),
              content: Text(row['name'] ?? 'Session'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Déconnecter'),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!ok || row['.id'] == null) return;
    await widget.service.disconnectPppActive(row['.id']!);
    await load();
  }

  Future<void> settingsPage() async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.pppMonitorSettings,
    );
    if (changed == true) {
      settings = await PppMonitorSettings.load();
      configureTimer();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('PPP actifs (${rows.length})'),
      actions: [
        IconButton(onPressed: settingsPage, icon: const Icon(Icons.tune)),
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Nom, service, IP, caller-id…',
            ),
          ),
        ),
        if (settings.autoRefresh)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Auto ${settings.refreshSeconds}s'),
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
                            AppRoutes.pppActiveDetail,
                            extra: PppActivePayload(r),
                          ),
                          leading: const CircleAvatar(
                            child: Icon(Icons.lan_outlined),
                          ),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'Service ${r['service'] ?? '—'}',
                              'IP ${r['address'] ?? '—'}',
                              if ((r['caller-id'] ?? '').isNotEmpty)
                                'Caller ${r['caller-id']}',
                              if ((r['uptime'] ?? '').isNotEmpty)
                                'Uptime ${r['uptime']}',
                              if ((r['encoding'] ?? '').isNotEmpty)
                                r['encoding']!,
                            ].join(' • '),
                          ),
                          trailing: IconButton(
                            onPressed: () => disconnect(r),
                            icon: const Icon(Icons.link_off),
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
