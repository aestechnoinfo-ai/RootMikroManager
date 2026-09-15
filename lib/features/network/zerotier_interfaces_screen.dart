import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class ZeroTierInterfacesScreen extends StatefulWidget {
  final RouterOsService service;
  const ZeroTierInterfacesScreen({super.key, required this.service});
  @override
  State<ZeroTierInterfacesScreen> createState() => _State();
}

class _State extends State<ZeroTierInterfacesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.zeroTierInterfaces();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? r]) async {
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.zeroTierInterfaceEdit,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> removeRow(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cette interface ZeroTier ?'),
            content: Text('${r['name'] ?? '—'} • ${r['network'] ?? '—'}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await widget.service.remove('/zerotier/interface', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('ZeroTier Interfaces'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une interface'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final r in rows)
                      Card(
                        child: ListTile(
                          onTap: () => edit(r),
                          leading: const Icon(Icons.hub_outlined),
                          title: Text(r['name'] ?? '—'),
                          subtitle: Text(
                            [
                              'network ${r['network'] ?? '—'}',
                              'status ${r['status'] ?? '—'}',
                              'managed ${r['allow-managed'] ?? '—'}',
                              'default ${r['allow-default'] ?? '—'}',
                            ].join(' • '),
                          ),
                          trailing: IconButton(
                            onPressed: () => removeRow(r),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
