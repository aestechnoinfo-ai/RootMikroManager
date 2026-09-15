import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';
import 'bridge_vlan_port_selector.dart';
import 'bridge_vlan_validator.dart';

class BridgeVlanEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const BridgeVlanEditorScreen({super.key, required this.service, this.row});

  @override
  State<BridgeVlanEditorScreen> createState() => _BridgeVlanEditorScreenState();
}

class _BridgeVlanEditorScreenState extends State<BridgeVlanEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController ids;
  late final TextEditingController comment;
  String bridge = '';
  bool loading = true;
  bool saving = false;
  bool listVlanCapable = false;
  List<String> bridges = [];
  List<String> interfaces = [];
  List<String> lists = [];
  Set<String> tagged = {};
  Set<String> untagged = {};

  @override
  void initState() {
    super.initState();
    ids = TextEditingController(text: widget.row?['vlan-ids'] ?? '');
    comment = TextEditingController(text: widget.row?['comment'] ?? '');
    bridge = widget.row?['bridge'] ?? '';
    tagged = BridgeVlanValidator.splitMembers(widget.row?['tagged']);
    untagged = BridgeVlanValidator.splitMembers(widget.row?['untagged']);
    load();
  }

  Future<void> load() async {
    final data = await Future.wait([
      widget.service.bridges(),
      widget.service.interfaces(),
      widget.service.interfaceLists(),
      widget.service.resource(),
    ]);
    final bridgeRows = data[0] as List<Map<String, String>>;
    final interfaceRows = data[1] as List<Map<String, String>>;
    final listRows = data[2] as List<Map<String, String>>;
    final resource = data[3] as Map<String, String>;
    bridges =
        bridgeRows
            .map((e) => e['name'] ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    interfaces =
        interfaceRows
            .map((e) => e['name'] ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    lists =
        listRows
            .map((e) => e['name'] ?? '')
            .where(
              (e) =>
                  e.isNotEmpty &&
                  !{'all', 'none', 'dynamic', 'static'}.contains(e),
            )
            .toList()
          ..sort();
    final version = resource['version'] ?? '';
    final match = RegExp(r'^(\d+)\.(\d+)').firstMatch(version);
    if (match != null) {
      final major = int.tryParse(match.group(1)!) ?? 0;
      final minor = int.tryParse(match.group(2)!) ?? 0;
      listVlanCapable = major > 7 || (major == 7 && minor >= 17);
    }
    if (bridge.isEmpty && bridges.isNotEmpty) bridge = bridges.first;
    if (bridge.isNotEmpty && !bridges.contains(bridge)) bridges.add(bridge);
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || saving) return;
    final overlap = tagged.intersection(untagged);
    if (overlap.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Même membre en tagged et untagged : ${overlap.join(', ')}.',
          ),
        ),
      );
      return;
    }
    if (BridgeVlanValidator.containsMultipleVlans(ids.text) &&
        untagged.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Plusieurs VLANs + ports untagged'),
              content: const Text(
                'MikroTik déconseille de grouper plusieurs VLAN IDs dans une même entrée comportant des ports access/untagged, car des trames peuvent sortir non taggées vers le mauvais port. Créez de préférence une entrée par VLAN access.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continuer malgré le risque'),
                ),
              ],
            ),
          ) ??
          false;
      if (!ok) return;
    }

    setState(() => saving = true);
    final values = <String, String>{
      'bridge': bridge,
      'vlan-ids': ids.text.trim(),
      'tagged': tagged.join(','),
      'untagged': untagged.join(','),
      'comment': comment.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/interface/bridge/vlan', values);
      } else {
        await widget.service.set('/interface/bridge/vlan', id, values);
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
  Widget build(BuildContext context) {
    final choices = <String>[...interfaces];
    if (listVlanCapable) choices.addAll(lists);
    choices.sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.row == null ? 'Ajouter Bridge VLAN' : 'Modifier Bridge VLAN',
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(isExpanded: true, 
                    value: bridge.isEmpty ? null : bridge,
                    decoration: const InputDecoration(labelText: 'Bridge'),
                    items: bridges
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => bridge = v ?? ''),
                    validator: (v) =>
                        (v ?? '').isEmpty ? 'Bridge requis' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: ids,
                    decoration: const InputDecoration(
                      labelText: 'VLAN IDs',
                      hintText: '10 ou 100-120,200',
                      helperText:
                          '1 à 4094 ; plusieurs VLANs surtout pour trunks/tagged',
                    ),
                    validator: (v) => BridgeVlanValidator.validVlanIds(v ?? '')
                        ? null
                        : 'VLAN IDs invalides',
                  ),
                  BridgeVlanPortSelector(
                    title: 'Tagged / trunks',
                    choices: choices,
                    selected: tagged,
                    onChanged: (v) => setState(() => tagged = v),
                  ),
                  BridgeVlanPortSelector(
                    title: 'Untagged / access',
                    choices: choices,
                    selected: untagged,
                    onChanged: (v) => setState(() => untagged = v),
                  ),
                  if (listVlanCapable)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'RouterOS 7.17+ détecté : les noms d’Interface Lists peuvent être utilisés directement dans tagged/untagged. current-tagged/current-untagged indiquent ensuite les membres réellement résolus.',
                        ),
                      ),
                    ),
                  TextField(
                    controller: comment,
                    decoration: const InputDecoration(labelText: 'Commentaire'),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        tagged.contains(bridge) || untagged.contains(bridge)
                            ? 'Le port CPU/bridge participe à cette entrée. Vérifiez qu’il s’agit volontairement du VLAN de management ou d’un VLAN routé.'
                            : 'Le bridge lui-même est le port CPU. Pour un management VLAN taggé ou du routage inter-VLAN, il doit généralement être membre tagged du VLAN concerné.',
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
  }

  @override
  void dispose() {
    ids.dispose();
    comment.dispose();
    super.dispose();
  }
}
