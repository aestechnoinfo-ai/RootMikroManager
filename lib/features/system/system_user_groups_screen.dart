import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemUserGroupsScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemUserGroupsScreen({super.key, required this.service});

  @override
  State<SystemUserGroupsScreen> createState() => _SystemUserGroupsScreenState();
}

class _SystemUserGroupsScreenState extends State<SystemUserGroupsScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.systemUserGroups();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Groupes utilisateurs'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(r['name'] ?? '—'),
                    subtitle: Text(
                      [
                        if ((r['policy'] ?? '').isNotEmpty)
                          'Policy ${r['policy']}',
                        if ((r['skin'] ?? '').isNotEmpty) 'Skin ${r['skin']}',
                      ].join(' • '),
                    ),
                  ),
                );
              },
            ),
          ),
  );
}
