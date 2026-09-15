import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class WifiProvisioningScreen extends StatefulWidget {
  final RouterOsService service;
  const WifiProvisioningScreen({super.key, required this.service});
  @override
  State<WifiProvisioningScreen> createState() => _S();
}

class _S extends State<WifiProvisioningScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.wifiProvisioning();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? r]) async {
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.wifiProvisioningEdit,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> toggle(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    await widget.service.set('/interface/wifi/provisioning', id, {
      'disabled': r['disabled'] == 'yes' ? 'no' : 'yes',
    });
    await load();
  }

  Future<void> removeRow(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cette règle ?'),
            content: Text(
              '${r['action'] ?? '—'} • ${r['master-configuration'] ?? '—'}',
            ),
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
      await widget.service.remove('/interface/wifi/provisioning', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('WiFi Provisioning'),
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
              label: const Text('Ajouter une règle'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (int i = 0; i < rows.length; i++)
                      Card(
                        child: ListTile(
                          onTap: () => edit(rows[i]),
                          leading: CircleAvatar(child: Text('${i + 1}')),
                          title: Text(rows[i]['action'] ?? '—'),
                          subtitle: Text(
                            'Master ${rows[i]['master-configuration'] ?? '—'} • MAC ${rows[i]['radio-mac'] ?? 'any'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'toggle') toggle(rows[i]);
                              if (v == 'delete') removeRow(rows[i]);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  rows[i]['disabled'] == 'yes'
                                      ? 'Activer'
                                      : 'Désactiver',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                            ],
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
