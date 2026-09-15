import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'internet_sharing_service.dart';

class InternetSharingAddScreen extends StatefulWidget {
  final RouterOsService service;
  const InternetSharingAddScreen({super.key, required this.service});

  @override
  State<InternetSharingAddScreen> createState() =>
      _InternetSharingAddScreenState();
}

class _InternetSharingAddScreenState extends State<InternetSharingAddScreen> {
  List<String> interfaces = [];
  String? selectedInterface;
  final ttl = TextEditingController(text: '1');
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    interfaces = await InternetSharingService(widget.service).interfaces();
    if (interfaces.isNotEmpty) selectedInterface = interfaces.first;
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final interfaceName = selectedInterface;
    if (interfaceName == null || saving) return;

    final ttlValue = int.tryParse(ttl.text.trim()) ?? 1;
    setState(() => saving = true);

    try {
      await InternetSharingService(
        widget.service,
      ).disableInternetSharing(interfaceName: interfaceName, ttl: ttlValue);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Désactiver partage Internet')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'RootMikroManager créera une règle Mangle '
                    'postrouting / change-ttl uniquement pour '
                    'l’interface sélectionnée.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(isExpanded: true, 
                value: selectedInterface,
                decoration: const InputDecoration(labelText: 'Interface'),
                items: interfaces
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => selectedInterface = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ttl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'TTL imposé',
                  helperText:
                      'Valeur par défaut : 1. Plage RouterOS : 1 à 255.',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: const Icon(Icons.block_outlined),
                label: Text(
                  selectedInterface == null
                      ? 'Aucune interface'
                      : 'Désactiver le partage sur '
                            '$selectedInterface',
                ),
              ),
            ],
          ),
  );

  @override
  void dispose() {
    ttl.dispose();
    super.dispose();
  }
}
