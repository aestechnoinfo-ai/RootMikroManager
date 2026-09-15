import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SnifferScreen extends StatefulWidget {
  final RouterOsService service;
  const SnifferScreen({super.key, required this.service});

  @override
  State<SnifferScreen> createState() => _SnifferScreenState();
}

class _SnifferScreenState extends State<SnifferScreen> {
  final fileName = TextEditingController(text: 'rootmikromanager-capture');
  final ipFilter = TextEditingController();
  bool loading = true;
  bool active = false;
  String interfaceName = '';
  List<String> interfaces = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    interfaces = (await widget.service.interfaces())
        .map((e) => e['name'] ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    if (interfaces.isNotEmpty) interfaceName = interfaces.first;
    try {
      final s = await widget.service.snifferSettings();
      active = s['running'] == 'yes' || s['running'] == 'true';
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> start() async {
    if (interfaceName.isEmpty) return;
    await widget.service.startSniffer(
      interfaceName: interfaceName,
      fileName: fileName.text.trim(),
      ipFilter: ipFilter.text.trim(),
    );
    if (mounted) setState(() => active = true);
  }

  Future<void> stop() async {
    await widget.service.stopSniffer();
    if (mounted) setState(() => active = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Packet Sniffer')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'La capture est enregistrée dans les fichiers du '
                    'routeur. Arrêtez la capture avant de récupérer ou '
                    'analyser le fichier.',
                  ),
                ),
              ),
              DropdownButtonFormField<String>(isExpanded: true, 
                value: interfaces.contains(interfaceName)
                    ? interfaceName
                    : null,
                decoration: const InputDecoration(labelText: 'Interface'),
                items: interfaces
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: active
                    ? null
                    : (v) => setState(() => interfaceName = v ?? interfaceName),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fileName,
                enabled: !active,
                decoration: const InputDecoration(labelText: 'Nom du fichier'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ipFilter,
                enabled: !active,
                decoration: const InputDecoration(
                  labelText: 'Filtre IP',
                  helperText: 'Optionnel, ex. 192.168.88.0/24',
                ),
              ),
              const SizedBox(height: 12),
              if (!active)
                FilledButton.icon(
                  onPressed: start,
                  icon: const Icon(Icons.fiber_manual_record),
                  label: const Text('Démarrer la capture'),
                )
              else
                FilledButton.icon(
                  onPressed: stop,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Arrêter la capture'),
                ),
            ],
          ),
  );

  @override
  void dispose() {
    fileName.dispose();
    ipFilter.dispose();
    super.dispose();
  }
}
