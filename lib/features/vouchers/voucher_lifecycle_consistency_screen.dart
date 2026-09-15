import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VoucherLifecycleConsistencyScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherLifecycleConsistencyScreen({super.key, required this.service});

  @override
  State<VoucherLifecycleConsistencyScreen> createState() => _State();
}

class _State extends State<VoucherLifecycleConsistencyScreen> {
  bool loading = true;
  int users = 0, active = 0, cookies = 0, schedulers = 0;
  int orphanActive = 0, orphanCookies = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final x = await Future.wait([
      widget.service.hotspotUsers(),
      widget.service.activeUsers(),
      widget.service.hotspotCookies(),
      widget.service.schedulers(),
    ]);
    final u = x[0], a = x[1], c = x[2], s = x[3];
    final names = u.map((e) => e['name'] ?? '').toSet();
    users = u.length;
    active = a.length;
    cookies = c.length;
    schedulers = s.length;
    orphanActive = a.where((e) => !names.contains(e['user'] ?? '')).length;
    orphanCookies = c.where((e) => !names.contains(e['user'] ?? '')).length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cohérence cycle de vie'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Tickets RouterOS'),
                  trailing: Text('$users'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Sessions actives'),
                  trailing: Text('$active'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Cookies'),
                  trailing: Text('$cookies'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Schedulers'),
                  trailing: Text('$schedulers'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(
                    orphanActive == 0
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                  ),
                  title: const Text('Sessions sans ticket'),
                  trailing: Text('$orphanActive'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(
                    orphanCookies == 0
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                  ),
                  title: const Text('Cookies sans ticket'),
                  trailing: Text('$orphanCookies'),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Audit non destructif. Pour un ticket supprimé ou expiré, '
                    'RootMikroManager doit retirer cookie, session active et scheduler '
                    'avant de retirer le ticket.',
                  ),
                ),
              ),
            ],
          ),
  );
}
