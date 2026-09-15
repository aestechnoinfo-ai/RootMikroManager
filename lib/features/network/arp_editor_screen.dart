import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'network_input_validator.dart';

class ArpEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const ArpEditorScreen({super.key, required this.service, this.row});

  @override
  State<ArpEditorScreen> createState() => _ArpEditorScreenState();
}

class _ArpEditorScreenState extends State<ArpEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController address;
  late final TextEditingController macAddress;
  late final TextEditingController comment;
  String interfaceName = '';
  bool published = false;
  bool loading = true;
  bool saving = false;
  List<String> interfaces = [];

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    address = TextEditingController(text: r?['address'] ?? '');
    macAddress = TextEditingController(text: r?['mac-address'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    interfaceName = r?['interface'] ?? '';
    published = r?['published'] == 'yes' || r?['published'] == 'true';
    load();
  }

  Future<void> load() async {
    interfaces = (await widget.service.interfaces())
        .map((e) => (e['name'] ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (interfaceName.isEmpty && interfaces.isNotEmpty) {
      interfaceName = interfaces.first;
    }
    if (!interfaces.contains(interfaceName) && interfaceName.isNotEmpty) {
      interfaces.add(interfaceName);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving || !(formKey.currentState?.validate() ?? false)) return;
    if (interfaceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une interface.')),
      );
      return;
    }

    setState(() => saving = true);
    final values = <String, String>{
      'address': address.text.trim(),
      'mac-address': macAddress.text.trim(),
      'interface': interfaceName,
      'published': published ? 'yes' : 'no',
      'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/ip/arp', values);
      else
        await widget.service.set('/ip/arp', id, values);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.row == null ? 'Ajouter ARP statique' : 'Modifier ARP'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: address,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Adresse IP'),
                  validator: NetworkInputValidator.ipv4,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: macAddress,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Adresse MAC',
                    hintText: 'AA:BB:CC:DD:EE:FF',
                  ),
                  validator: NetworkInputValidator.mac,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(isExpanded: true, 
                  value: interfaces.contains(interfaceName)
                      ? interfaceName
                      : null,
                  decoration: const InputDecoration(labelText: 'Interface'),
                  items: interfaces
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => interfaceName = v ?? interfaceName),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: comment,
                  decoration: const InputDecoration(labelText: 'Commentaire'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Published / Proxy ARP individuel'),
                  value: published,
                  onChanged: (v) => setState(() => published = v),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
  );

  @override
  void dispose() {
    address.dispose();
    macAddress.dispose();
    comment.dispose();
    super.dispose();
  }
}
