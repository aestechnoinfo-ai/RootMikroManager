import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';
import 'bridge_vlan_validator.dart';

class VlanEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const VlanEditorScreen({super.key, required this.service, this.row});

  @override
  State<VlanEditorScreen> createState() => _VlanEditorScreenState();
}

class _VlanEditorScreenState extends State<VlanEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController vlanId;
  late final TextEditingController mtu;
  late final TextEditingController comment;
  String parent = '';
  bool useServiceTag = false;
  bool enabled = true;
  bool loading = true;
  bool saving = false;
  List<String> interfaces = [];

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    vlanId = TextEditingController(text: r?['vlan-id'] ?? '10');
    mtu = TextEditingController(text: r?['mtu'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    parent = r?['interface'] ?? '';
    useServiceTag =
        r?['use-service-tag'] == 'yes' || r?['use-service-tag'] == 'true';
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
    load();
  }

  Future<void> load() async {
    interfaces =
        (await widget.service.interfaces())
            .map((e) => (e['name'] ?? '').trim())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    if (parent.isEmpty && interfaces.isNotEmpty) parent = interfaces.first;
    if (!interfaces.contains(parent) && parent.isNotEmpty)
      interfaces.add(parent);
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || saving) return;
    if (useServiceTag) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Service VLAN / S-Tag'),
              content: const Text(
                'use-service-tag utilise le tag de service (802.1ad). Activez-le uniquement si le parent/bridge est réellement configuré pour ce type de VLAN.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          ) ??
          false;
      if (!ok) return;
    }

    setState(() => saving = true);
    try {
      final values = <String, String>{
        'name': name.text.trim(),
        'interface': parent,
        'vlan-id': vlanId.text.trim(),
        'use-service-tag': useServiceTag ? 'yes' : 'no',
        'disabled': enabled ? 'no' : 'yes',
        if (mtu.text.trim().isNotEmpty) 'mtu': mtu.text.trim(),
        'comment': comment.text.trim(),
      };
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/interface/vlan', values);
      } else {
        await widget.service.set('/interface/vlan', id, values);
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
      title: Text(widget.row == null ? 'Ajouter VLAN' : 'Modifier VLAN'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: interfaces.contains(parent) ? parent : null,
                  decoration: const InputDecoration(
                    labelText: 'Interface parent',
                  ),
                  items: interfaces
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => parent = v ?? parent),
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Interface requise' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: vlanId,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'VLAN ID',
                    helperText: '1 à 4094',
                  ),
                  validator: (v) => BridgeVlanValidator.validVlanId(v ?? '')
                      ? null
                      : 'VLAN ID invalide',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: mtu,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'MTU',
                    helperText: 'Vide ou 576–65535',
                  ),
                  validator: (v) => BridgeVlanValidator.validMtu(v ?? '')
                      ? null
                      : 'MTU invalide',
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use Service Tag'),
                  subtitle: const Text(
                    '802.1ad / S-Tag ; ne pas activer pour un VLAN 802.1Q standard.',
                  ),
                  value: useServiceTag,
                  onChanged: (v) => setState(() => useServiceTag = v),
                ),
                TextField(
                  controller: comment,
                  decoration: const InputDecoration(labelText: 'Commentaire'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activée'),
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                ),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Lorsqu’une interface VLAN est créée directement sur un bridge avec VLAN Filtering, RouterOS peut créer une appartenance dynamique dans le Bridge VLAN Table. Vérifiez current-tagged/current-untagged après modification.',
                    ),
                  ),
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
    name.dispose();
    vlanId.dispose();
    mtu.dispose();
    comment.dispose();
    super.dispose();
  }
}
