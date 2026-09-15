import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';
import 'bridge_vlan_validator.dart';

class BridgeEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const BridgeEditorScreen({super.key, required this.service, this.row});

  @override
  State<BridgeEditorScreen> createState() => _BridgeEditorScreenState();
}

class _BridgeEditorScreenState extends State<BridgeEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController mtu;
  late final TextEditingController comment;
  String protocolMode = 'rstp';
  bool igmpSnooping = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? 'bridge1');
    mtu = TextEditingController(text: r?['mtu'] ?? 'auto');
    comment = TextEditingController(text: r?['comment'] ?? '');
    protocolMode = r?['protocol-mode'] ?? 'rstp';
    igmpSnooping =
        r?['igmp-snooping'] == 'yes' || r?['igmp-snooping'] == 'true';
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || saving) return;
    setState(() => saving = true);
    final values = <String, String>{
      'name': name.text.trim(),
      'protocol-mode': protocolMode,
      'igmp-snooping': igmpSnooping ? 'yes' : 'no',
      'comment': comment.text.trim(),
      if (mtu.text.trim().isNotEmpty) 'mtu': mtu.text.trim(),
    };
    final id = widget.row?['.id'];
    try {
      if (id == null) {
        values['vlan-filtering'] = 'no';
        await widget.service.add('/interface/bridge', values);
      } else {
        await widget.service.set('/interface/bridge', id, values);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.row == null ? 'Ajouter bridge' : 'Modifier bridge'),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Nom requis';
              if (value.length > 63) return 'Nom trop long';
              if (RegExp(r'[\r\n]').hasMatch(value)) return 'Nom invalide';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: mtu,
            decoration: const InputDecoration(
              labelText: 'MTU',
              helperText: 'auto ou 576–65535',
            ),
            validator: (v) =>
                BridgeVlanValidator.validMtu(v ?? '') ? null : 'MTU invalide',
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: protocolMode,
            decoration: const InputDecoration(labelText: 'Protocol Mode'),
            items: const [
              'none',
              'stp',
              'rstp',
              'mstp',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => protocolMode = v ?? 'rstp'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: comment,
            decoration: const InputDecoration(labelText: 'Commentaire'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('IGMP Snooping'),
            value: igmpSnooping,
            onChanged: (v) => setState(() => igmpSnooping = v),
          ),
          if (widget.row != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('VLAN Filtering'),
                subtitle: const Text(
                  'L’activation est volontairement séparée et protégée par un audit de management.',
                ),
              ),
            ),
          const SizedBox(height: 8),
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
    name.dispose();
    mtu.dispose();
    comment.dispose();
    super.dispose();
  }
}
