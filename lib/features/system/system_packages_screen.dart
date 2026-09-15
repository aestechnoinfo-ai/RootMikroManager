import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemPackagesScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemPackagesScreen({super.key, required this.service});

  @override
  State<SystemPackagesScreen> createState() => _SystemPackagesScreenState();
}

class _SystemPackagesScreenState extends State<SystemPackagesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  Map<String, String> update = {};
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      rows = await widget.service.systemPackages();
      update = await widget.service.packageUpdateStatus();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> checkUpdates() async {
    await widget.service.checkForUpdates();
    await Future<void>.delayed(const Duration(seconds: 1));
    await load();
  }

  Future<void> install() async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Installer la mise à jour ?'),
            content: const Text(
              'Le routeur peut télécharger les packages puis redémarrer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Installer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await widget.service.installPackageUpdate();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Packages / mises à jour'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mise à jour RouterOS',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Installée : ${update['installed-version'] ?? '—'}',
                        ),
                        Text('Dernière : ${update['latest-version'] ?? '—'}'),
                        Text('Canal : ${update['channel'] ?? '—'}'),
                        Text('Statut : ${update['status'] ?? '—'}'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: checkUpdates,
                              icon: const Icon(Icons.search),
                              label: const Text('Vérifier les mises à jour'),
                            ),
                            FilledButton.icon(
                              onPressed: install,
                              icon: const Icon(Icons.system_update_alt),
                              label: const Text('Installer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (final row in rows)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(row['name'] ?? 'Package'),
                      subtitle: Text(
                        [
                          'Version: ${row['version'] ?? '—'}',
                          if ((row['build-time'] ?? '').isNotEmpty)
                            'Build: ${row['build-time']}',
                          if ((row['scheduled'] ?? '').isNotEmpty)
                            'Planifié: ${row['scheduled']}',
                        ].join(' • '),
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}
