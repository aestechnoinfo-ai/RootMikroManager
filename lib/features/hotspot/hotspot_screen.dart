import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotScreen({super.key, required this.service});
  @override
  State<HotspotScreen> createState() => _HotspotScreenState();
}

class _HotspotScreenState extends State<HotspotScreen>
    with SingleTickerProviderStateMixin {
  late TabController tab;
  List<Map<String, String>> users = [], active = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    tab = TabController(length: 2, vsync: this);
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      users = await widget.service.hotspotUsers();
      active = await widget.service.activeUsers();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Hotspot'),
      bottom: TabBar(
        controller: tab,
        tabs: [
          Tab(text: 'Utilisateurs (${users.length})'),
          Tab(text: 'Actifs (${active.length})'),
        ],
      ),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : TabBarView(
            controller: tab,
            children: [_list(users, false), _list(active, true)],
          ),
  );
  Widget _list(List<Map<String, String>> x, bool a) => ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: x.length,
    itemBuilder: (c, i) {
      final u = x[i];
      return Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(a ? Icons.wifi : Icons.person)),
          title: Text(u['name'] ?? u['user'] ?? '—'),
          subtitle: Text(
            [
              u['profile'],
              u['address'],
              u['uptime'],
            ].whereType<String>().join(' • '),
          ),
          trailing: !a
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final id = u['.id'];
                    if (id != null) {
                      await widget.service.remove('/ip/hotspot/user', id);
                      await load();
                    }
                  },
                )
              : null,
        ),
      );
    },
  );
  @override
  void dispose() {
    tab.dispose();
    super.dispose();
  }
}
