import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotIpBindingEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const HotspotIpBindingEditorScreen({
    super.key,
    required this.service,
    this.row,
  });

  @override
  State<HotspotIpBindingEditorScreen> createState() =>
      _HotspotIpBindingEditorScreenState();
}

class _HotspotIpBindingEditorScreenState
    extends State<HotspotIpBindingEditorScreen> {
  late final TextEditingController mac;
  late final TextEditingController address;
  late final TextEditingController toAddress;
  late final TextEditingController comment;
  String type = 'regular';
  String server = 'all';
  bool enabled = true;
  bool loading = true;
  List<Map<String, String>> servers = [];

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    mac = TextEditingController(text: r?['mac-address'] ?? '');
    address = TextEditingController(text: r?['address'] ?? '');
    toAddress = TextEditingController(text: r?['to-address'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    type = r?['type'] ?? 'regular';
    server = (r?['server'] ?? '').isEmpty ? 'all' : r!['server']!;
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
    load();
  }

  Future<void> load() async {
    servers = await widget.service.hotspotServers();
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (mac.text.trim().isEmpty && address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MAC ou Address obligatoire.')),
      );
      return;
    }
    final values = <String, String>{
      if (mac.text.trim().isNotEmpty) 'mac-address': mac.text.trim(),
      if (address.text.trim().isNotEmpty) 'address': address.text.trim(),
      if (toAddress.text.trim().isNotEmpty) 'to-address': toAddress.text.trim(),
      'server': server,
      'type': type,
      'disabled': enabled ? 'no' : 'yes',
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };
    final id = widget.row?['.id'];
    if (id == null) {
      await widget.service.add('/ip/hotspot/ip-binding', values);
    } else {
      await widget.service.set('/ip/hotspot/ip-binding', id, values);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null ? 'Ajouter IP Binding' : 'Modifier IP Binding',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: mac,
                decoration: const InputDecoration(labelText: 'MAC Address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: toAddress,
                decoration: const InputDecoration(labelText: 'To Address'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: server,
                decoration: const InputDecoration(labelText: 'Server'),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('all')),
                  ...servers.map(
                    (r) => DropdownMenuItem(
                      value: r['name'] ?? '',
                      child: Text(r['name'] ?? '—'),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => server = v ?? 'all'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'regular', child: Text('regular')),
                  DropdownMenuItem(value: 'bypassed', child: Text('bypassed')),
                  DropdownMenuItem(value: 'blocked', child: Text('blocked')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'regular'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: comment,
                decoration: const InputDecoration(labelText: 'Commentaire'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activé'),
                value: enabled,
                onChanged: (v) => setState(() => enabled = v),
              ),
              FilledButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
  );

  @override
  void dispose() {
    mac.dispose();
    address.dispose();
    toAddress.dispose();
    comment.dispose();
    super.dispose();
  }
}
