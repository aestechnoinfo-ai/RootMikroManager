import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class DeviceModeToolsScreen extends StatefulWidget {
  final RouterOsService service;
  const DeviceModeToolsScreen({super.key, required this.service});

  @override
  State<DeviceModeToolsScreen> createState() => _DeviceModeToolsScreenState();
}

class _DeviceModeToolsScreenState extends State<DeviceModeToolsScreen> {
  bool loading = true;
  Map<String, String> row = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      row = await widget.service.deviceMode();
    } catch (_) {
      row = {};
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Device Mode'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Lecture seule dans RootMikroManager. Certaines '
                    'fonctions de diagnostic peuvent être interdites par '
                    'le Device Mode du routeur. Leur activation peut '
                    'nécessiter une validation physique sur l’appareil.',
                  ),
                ),
              ),
              if (row.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('Device Mode indisponible'),
                    subtitle: Text(
                      'Cette version de RouterOS ne retourne pas ces '
                      'informations ou les droits sont insuffisants.',
                    ),
                  ),
                ),
              for (final e in row.entries.where((e) => e.value.isNotEmpty))
                Card(
                  child: ListTile(title: Text(e.key), trailing: Text(e.value)),
                ),
            ],
          ),
  );
}
