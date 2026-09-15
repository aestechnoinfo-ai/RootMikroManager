import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/navigation/navigation_payloads.dart';

import '../../core/routeros/routeros_service.dart';
import 'hotspot_monitor_settings.dart';

class HotspotActiveScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotActiveScreen({super.key, required this.service});

  @override
  State<HotspotActiveScreen> createState() => _HotspotActiveScreenState();
}

class _HotspotActiveScreenState extends State<HotspotActiveScreen>
    with WidgetsBindingObserver {
  final search = TextEditingController();
  List<Map<String, String>> rows = [];
  List<Map<String, String>> servers = [];
  String server = 'all';
  bool loading = true;
  bool refreshing = false;
  HotspotMonitorSettings settings = const HotspotMonitorSettings();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    search.addListener(() => setState(() {}));
    bootstrap();
  }

  Future<void> bootstrap() async {
    settings = await HotspotMonitorSettings.load();
    servers = await widget.service.hotspotServers();
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
      rows = await widget.service.activeUsers(server: server);
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

  Future<void> openUser(Map<String, String> active) async {
    final name = (active['user'] ?? '').trim();
    if (name.isEmpty) return;
    final users = await widget.service.hotspotUsersByName(name);
    if (!mounted || users.isEmpty) return;
    await AppRouter.pushNamed(
      context,
      AppRoutes.hotspotUserEdit,
      extra: HotspotUserPayload(users.first),
    );
    await load();
  }

  Future<void> disconnect(Map<String, String> row) async {
    var ok = true;
    if (settings.confirmDisconnect) {
      ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Déconnecter la session ?'),
              content: Text(row['user'] ?? 'Utilisateur Hotspot'),
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
    if (!ok) return;
    final id = row['.id'];
    if (id == null) return;
    await widget.service.disconnectHotspotActive(id);
    await load();
  }

  String bytes(String? raw) {
    final n = double.tryParse(raw ?? '') ?? 0;
    if (n >= 1073741824) return '${(n / 1073741824).toStringAsFixed(2)} GB';
    if (n >= 1048576) return '${(n / 1048576).toStringAsFixed(1)} MB';
    if (n >= 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    return '${n.toInt()} B';
  }

  Future<void> openSettings() async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.hotspotMonitorSettings,
    );
    if (changed == true) {
      settings = await HotspotMonitorSettings.load();
      configureTimer();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Hotspot actifs (${rows.length})'),
      actions: [
        IconButton(onPressed: openSettings, icon: const Icon(Icons.tune)),
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, c) {
              final searchField = TextField(
                controller: search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Utilisateur, IP, MAC…',
                ),
              );
              final serverField = DropdownButtonFormField<String>(
                value: server,
                decoration: const InputDecoration(labelText: 'Serveur'),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Tous')),
                  ...servers.map(
                    (r) => DropdownMenuItem(
                      value: r['name'] ?? '',
                      child: Text(r['name'] ?? '—'),
                    ),
                  ),
                ],
                onChanged: (v) async {
                  server = v ?? 'all';
                  await load();
                },
              );
              if (c.maxWidth < 650) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 8),
                    serverField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  Expanded(child: serverField),
                ],
              );
            },
          ),
        ),
        if (settings.autoRefresh)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      final row = visible[i];
                      return Card(
                        child: ListTile(
                          onTap: () => openUser(row),
                          leading: const CircleAvatar(
                            child: Icon(Icons.wifi_tethering),
                          ),
                          title: Text(row['user'] ?? '—'),
                          subtitle: Text(
                            [
                              'IP ${row['address'] ?? '—'}',
                              'MAC ${row['mac-address'] ?? '—'}',
                              'Server ${row['server'] ?? '—'}',
                              'Uptime ${row['uptime'] ?? '—'}',
                              if (settings.showTraffic)
                                '↓ ${bytes(row['bytes-in'])} ↑ ${bytes(row['bytes-out'])}',
                              if ((row['session-time-left'] ?? '').isNotEmpty)
                                'Reste ${row['session-time-left']}',
                            ].join(' • '),
                          ),
                          trailing: IconButton(
                            tooltip: 'Déconnecter',
                            onPressed: () => disconnect(row),
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
