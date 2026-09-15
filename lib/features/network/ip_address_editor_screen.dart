import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';
import 'network_input_validator.dart';

class IpAddressEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const IpAddressEditorScreen({super.key, required this.service, this.row});

  @override
  State<IpAddressEditorScreen> createState() => _IpAddressEditorScreenState();
}

class _IpAddressEditorScreenState extends State<IpAddressEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController address;
  late final TextEditingController network;
  late final TextEditingController comment;
  List<String> interfaces = [];
  String interfaceName = '';
  bool loading = true;
  bool saving = false;

  bool get editing => widget.row != null;
  bool get dynamic =>
      widget.row?['dynamic'] == 'yes' || widget.row?['dynamic'] == 'true';

  @override
  void initState() {
    super.initState();
    final row = widget.row;
    address = TextEditingController(text: row?['address'] ?? '');
    network = TextEditingController(text: row?['network'] ?? '');
    comment = TextEditingController(text: row?['comment'] ?? '');
    interfaceName = row?['interface'] ?? '';
    loadInterfaces();
  }

  Future<void> loadInterfaces() async {
    try {
      interfaces =
          (await widget.service.interfaces())
              .map((e) => (e['name'] ?? '').trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      if (interfaceName.isEmpty && interfaces.isNotEmpty) {
        interfaceName = interfaces.first;
      }
      if (interfaceName.isNotEmpty && !interfaces.contains(interfaceName)) {
        interfaces.add(interfaceName);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (dynamic || saving || !(formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (interfaceName.isEmpty) {
      _message('Sélectionnez une interface.');
      return;
    }

    setState(() => saving = true);
    final values = <String, String>{
      'address': address.text.trim(),
      'interface': interfaceName,
      if (network.text.trim().isNotEmpty) 'network': network.text.trim(),
      'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ip/address', values);
      } else {
        await widget.service.set('/ip/address', id, values);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _message('$e');
      setState(() => saving = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(editing ? 'Modifier adresse IPv4' : 'Ajouter adresse IPv4'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (dynamic)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Cette adresse est dynamique. RootMikroManager la '
                        'laisse en lecture seule : modifiez sa source '
                        '(DHCP, PPP, VPN…) plutôt que /ip/address.',
                      ),
                    ),
                  ),
                TextFormField(
                  controller: address,
                  enabled: !dynamic,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Adresse/prefix',
                    hintText: '192.168.88.1/24',
                  ),
                  validator: NetworkInputValidator.ipv4Cidr,
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
                  onChanged: dynamic
                      ? null
                      : (v) => setState(() => interfaceName = v ?? ''),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: network,
                  enabled: !dynamic,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Network',
                    helperText: 'Optionnel : RouterOS peut le déterminer.',
                  ),
                  validator: (v) =>
                      NetworkInputValidator.ipv4OrEmpty(v, label: 'Network'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: comment,
                  enabled: !dynamic,
                  decoration: const InputDecoration(labelText: 'Commentaire'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: dynamic || saving ? null : save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Enregistrement…' : 'Enregistrer'),
                ),
              ],
            ),
          ),
  );

  @override
  void dispose() {
    address.dispose();
    network.dispose();
    comment.dispose();
    super.dispose();
  }
}
