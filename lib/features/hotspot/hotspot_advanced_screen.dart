import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/navigation/navigation_payloads.dart';

import '../../core/routeros/routeros_service.dart';
import 'hotspot_monitor_settings_screen.dart';
import 'hotspot_monitor_settings.dart';

class HotspotAdvancedScreen extends StatefulWidget {
  final RouterOsService service;

  const HotspotAdvancedScreen({super.key, required this.service});

  @override
  State<HotspotAdvancedScreen> createState() => _HotspotAdvancedScreenState();
}

class _HotspotAdvancedScreenState extends State<HotspotAdvancedScreen> {
  final search = TextEditingController();

  int section = 0;
  bool loading = true;
  String? error;

  String activeServer = 'all';
  String hostFilter = 'all';
  HotspotMonitorSettings monitorSettings = const HotspotMonitorSettings();
  Timer? activeTimer;
  List<Map<String, String>> rows = [];
  List<Map<String, String>> servers = [];

  @override
  void initState() {
    super.initState();
    search.addListener(_refreshLocal);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    monitorSettings = await HotspotMonitorSettings.load();
    await load();
    _configureActiveTimer();
  }

  void _configureActiveTimer() {
    activeTimer?.cancel();
    if (!monitorSettings.autoRefresh || section != 0) return;

    activeTimer = Timer.periodic(
      Duration(seconds: monitorSettings.refreshSeconds),
      (_) => load(background: true),
    );
  }

  Future<void> load({bool background = false}) async {
    if (!background && mounted) {
      setState(() => loading = true);
    }

    try {
      if (servers.isEmpty) {
        servers = await widget.service.hotspotServers();
      }

      if (section == 0) {
        rows = await widget.service.activeUsers(server: activeServer);
      } else if (section == 1) {
        rows = await widget.service.hotspotHosts(
          authorizedOnly: hostFilter == 'authorized',
          bypassedOnly: hostFilter == 'bypassed',
        );
      } else if (section == 2) {
        rows = await widget.service.hotspotCookies();
      } else {
        rows = await widget.service.hotspotIpBindings();
      }

      error = null;
    } catch (e) {
      error = '$e';
    }

    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visibleRows {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;

    return rows.where((row) {
      return row.values.any((value) => value.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> openActiveUser(Map<String, String> active) async {
    final name = (active['user'] ?? '').trim();
    if (name.isEmpty) return;

    try {
      final users = await widget.service.hotspotUsersByName(name);
      if (!mounted) return;

      if (users.isEmpty) {
        _message('Utilisateur Hotspot introuvable : $name');
        return;
      }

      await AppRouter.pushNamed(
        context,
        AppRoutes.hotspotUserEdit,
        extra: HotspotUserPayload(users.first),
      );

      if (mounted) await load();
    } catch (e) {
      _message('$e');
    }
  }

  Future<void> disconnect(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;

    final ok = await _confirm(
      'Déconnecter ${row['user'] ?? 'cet utilisateur'} ?',
      'Comme RootMikroManager officiel, RootMikroManager supprimera '
          'le cookie Hotspot de ce user puis sa session active.',
    );
    if (!ok) return;

    try {
      await widget.service.disconnectHotspotActive(id);
      await load();
    } catch (e) {
      _message('$e');
    }
  }

  Future<void> removeCookie(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;

    if (!await _confirm(
      'Supprimer ce cookie ?',
      '${row['user'] ?? ''} ${row['mac-address'] ?? ''}',
    ))
      return;

    try {
      await widget.service.removeHotspotCookie(id);
      await load();
    } catch (e) {
      _message('$e');
    }
  }

  Future<void> removeHost(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;

    if (!await _confirm(
      'Supprimer ce host ?',
      '${row['mac-address'] ?? ''} ${row['address'] ?? ''}',
    ))
      return;

    try {
      await widget.service.removeHotspotHost(id);
      await load();
    } catch (e) {
      _message('$e');
    }
  }

  Future<void> hostToBinding(Map<String, String> row) async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Créer IP Binding'),
        children: [
          for (final value in ['bypassed', 'blocked', 'regular'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Text(value),
            ),
        ],
      ),
    );
    if (type == null) return;

    try {
      await widget.service.makeHotspotHostBinding(
        row,
        type: type,
        comment: 'RootMikroManager Host Binding',
      );
      _message('IP Binding créé.');
    } catch (e) {
      _message('$e');
    }
  }

  Future<void> bindingEditor([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.hotspotIpBindingEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> bindingAction(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;

    try {
      if (action == 'edit') {
        await bindingEditor(row);
        return;
      }

      if (action == 'enable') {
        await widget.service.enable('/ip/hotspot/ip-binding', id);
      } else if (action == 'disable') {
        await widget.service.disable('/ip/hotspot/ip-binding', id);
      } else if (action == 'delete') {
        final ok = await _confirm(
          'Supprimer cet IP Binding ?',
          'La logique RootMikroManager supprimera aussi, lorsqu’ils existent, '
              'la Simple Queue et le Scheduler portant la MAC, '
              'ainsi que l’entrée ARP et le bail DHCP portant '
              'l’adresse IP du binding.',
        );
        if (!ok) return;

        await widget.service.removeHotspotIpBindingWithRootMikroManagerCleanup(
          row,
        );
      }

      await load();
    } catch (e) {
      _message('$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hotspot avancé')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Actifs'),
                  icon: Icon(Icons.people_outline),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Hosts'),
                  icon: Icon(Icons.devices_outlined),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('Cookies'),
                  icon: Icon(Icons.cookie_outlined),
                ),
                ButtonSegment(
                  value: 3,
                  label: Text('IP Binding'),
                  icon: Icon(Icons.link),
                ),
              ],
              selected: {section},
              onSelectionChanged: (v) {
                section = v.first;
                _configureActiveTimer();
                load();
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, c) {
              final searchField = TextField(
                controller: search,
                decoration: const InputDecoration(
                  labelText: 'Recherche',
                  prefixIcon: Icon(Icons.search),
                ),
              );

              if (section != 0) return searchField;

              final serverField = DropdownButtonFormField<String>(isExpanded: true, 
                value: activeServer,
                decoration: const InputDecoration(labelText: 'Server'),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Tous les serveurs'),
                  ),
                  ...servers.map(
                    (row) => DropdownMenuItem(
                      value: row['name'] ?? '',
                      child: Text(row['name'] ?? '—'),
                    ),
                  ),
                ],
                onChanged: (v) async {
                  activeServer = v ?? 'all';
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
        if (section == 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('Tous')),
                  ButtonSegment(
                    value: 'authorized',
                    label: Text('Authorized'),
                    icon: Icon(Icons.verified_user_outlined),
                  ),
                  ButtonSegment(
                    value: 'bypassed',
                    label: Text('Bypassed'),
                    icon: Icon(Icons.fast_forward_outlined),
                  ),
                ],
                selected: {hostFilter},
                onSelectionChanged: (value) async {
                  hostFilter = value.first;
                  await load();
                },
              ),
            ),
          ),
        if (section == 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => bindingEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter IP Binding'),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                  child: FilledButton.icon(
                    onPressed: load,
                    icon: const Icon(Icons.refresh),
                    label: Text(error!),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${visibleRows.length} élément(s)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (section == 0 && monitorSettings.autoRefresh)
                            Text(
                              'Auto ${monitorSettings.refreshSeconds}s',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (visibleRows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(
                            child: Text('Aucun élément pour ce filtre.'),
                          ),
                        ),
                      ...visibleRows.map(_card),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );

  Widget _card(Map<String, String> row) {
    final disabled = row['disabled'] == 'true' || row['disabled'] == 'yes';

    if (section == 0) {
      return Card(
        child: ListTile(
          onTap: () => openActiveUser(row),
          leading: CircleAvatar(
            backgroundColor: Colors.green.withValues(alpha: 0.12),
            child: const Icon(
              Icons.wifi_tethering_outlined,
              color: Colors.green,
            ),
          ),
          title: Text(row['user'] ?? '—'),
          subtitle: Text(
            [
              'Server: ${row['server'] ?? '—'}',
              'Address: ${row['address'] ?? '—'}',
              'MAC: ${row['mac-address'] ?? '—'}',
              'Uptime: ${row['uptime'] ?? '—'}',
              'Bytes In: ${_formatBytes(row['bytes-in'])}',
              'Bytes Out: ${_formatBytes(row['bytes-out'])}',
              'Time Left: ${row['session-time-left'] ?? '—'}',
              'Login By: ${row['login-by'] ?? '—'}',
              if ((row['comment'] ?? '').isNotEmpty) row['comment']!,
            ].join(' • '),
          ),
          trailing: IconButton(
            tooltip: 'Déconnecter',
            onPressed: () => disconnect(row),
            icon: const Icon(Icons.link_off),
          ),
        ),
      );
    }

    if (section == 1) {
      final badges = <String>[
        if (row['authorized'] == 'true' || row['authorized'] == 'yes') 'A',
        if (row['DHCP'] == 'true' || row['DHCP'] == 'yes') 'H',
        if (row['dynamic'] == 'true' || row['dynamic'] == 'yes') 'D',
        if (row['bypassed'] == 'true' || row['bypassed'] == 'yes') 'P',
      ];

      return Card(
        child: ListTile(
          onTap: () => AppRouter.pushNamed(
            context,
            AppRoutes.hotspotHostDetail,
            extra: HotspotHostPayload(row),
          ),
          leading: CircleAvatar(
            backgroundColor: (badges.contains('P') ? Colors.blue : Colors.green)
                .withValues(alpha: 0.12),
            child: Icon(
              Icons.devices_outlined,
              color: badges.contains('P') ? Colors.blue : Colors.green,
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(row['mac-address'] ?? '—')),
              if (badges.isNotEmpty)
                Text(
                  badges.join(' '),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: badges.contains('P') ? Colors.blue : Colors.green,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            [
              'Address: ${row['address'] ?? '—'}',
              'To Address: ${row['to-address'] ?? '—'}',
              'Server: ${row['server'] ?? '—'}',
              if ((row['comment'] ?? '').isNotEmpty) row['comment']!,
            ].join(' • '),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'binding') {
                hostToBinding(row);
              } else if (value == 'delete') {
                removeHost(row);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'binding', child: Text('Créer IP Binding')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer Host')),
            ],
          ),
        ),
      );
    }

    if (section == 2) {
      final expires = (row['expires-in'] ?? '').trim();
      final expiring =
          expires.startsWith('0s') ||
          expires.startsWith('1m') ||
          expires.startsWith('2m') ||
          expires.startsWith('3m') ||
          expires.startsWith('4m') ||
          expires.startsWith('5m');

      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (expiring ? Colors.orange : Colors.teal)
                .withValues(alpha: 0.12),
            child: Icon(
              Icons.cookie_outlined,
              color: expiring ? Colors.orange : Colors.teal,
            ),
          ),
          title: Text(row['user'] ?? '—'),
          subtitle: Text(
            [
              'MAC: ${row['mac-address'] ?? '—'}',
              'Domain: ${row['domain'] ?? '—'}',
              'Expires In: ${row['expires-in'] ?? '—'}',
            ].join(' • '),
          ),
          trailing: IconButton(
            tooltip: 'Supprimer cookie',
            onPressed: () => removeCookie(row),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: Icon(disabled ? Icons.link_off : Icons.link),
        title: Text(
          (row['comment'] ?? '').isNotEmpty
              ? row['comment']!
              : row['mac-address'] ?? '—',
        ),
        subtitle: Text(
          [
            'MAC: ${row['mac-address'] ?? '—'}',
            'Address: ${row['address'] ?? '—'}',
            'To Address: ${row['to-address'] ?? '—'}',
            'Server: ${row['server'] ?? '—'}',
            'Type: ${row['type'] ?? 'regular'}',
            disabled ? 'DISABLED' : 'ENABLED',
          ].join(' • '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => bindingAction(v, row),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(
              value: disabled ? 'enable' : 'disable',
              child: Text(disabled ? 'Activer' : 'Désactiver'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  String _formatBytes(String? raw) {
    var value = (int.tryParse(raw ?? '') ?? 0).toDouble();
    if (value <= 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }

    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} '
        '${units[index]}';
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ) ??
      false;

  void _refreshLocal() {
    if (mounted) setState(() {});
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    activeTimer?.cancel();
    search.removeListener(_refreshLocal);
    search.dispose();
    super.dispose();
  }
}
