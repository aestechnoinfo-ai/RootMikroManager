import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';
import 'bridge_vlan_validator.dart';

class BridgePortEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String> row;
  const BridgePortEditorScreen({
    super.key,
    required this.service,
    required this.row,
  });

  @override
  State<BridgePortEditorScreen> createState() => _BridgePortEditorScreenState();
}

class _BridgePortEditorScreenState extends State<BridgePortEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController pvid;
  late final TextEditingController comment;
  late final TextEditingController horizon;
  late final TextEditingController pathCost;
  late final TextEditingController internalPathCost;
  late String frame;
  late String edge;
  late String pointToPoint;
  late bool ingress;
  late bool bpduGuard;
  late bool restrictedRole;
  late bool restrictedTcn;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    pvid = TextEditingController(text: widget.row['pvid'] ?? '1');
    comment = TextEditingController(text: widget.row['comment'] ?? '');
    horizon = TextEditingController(text: widget.row['horizon'] ?? 'none');
    pathCost = TextEditingController(text: widget.row['path-cost'] ?? '10');
    internalPathCost = TextEditingController(
      text: widget.row['internal-path-cost'] ?? '10',
    );
    frame = widget.row['frame-types'] ?? 'admit-all';
    edge = widget.row['edge'] ?? 'auto';
    pointToPoint = widget.row['point-to-point'] ?? 'auto';
    ingress = widget.row['ingress-filtering'] == 'yes';
    bpduGuard = widget.row['bpdu-guard'] == 'yes';
    restrictedRole = widget.row['restricted-role'] == 'yes';
    restrictedTcn = widget.row['restricted-tcn'] == 'yes';
  }

  bool get trunkLike => frame == 'admit-only-vlan-tagged';
  bool get accessLike => frame == 'admit-only-untagged-and-priority-tagged';

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || saving) return;
    if (trunkLike && !ingress) {
      final ok = await _confirm(
        'Trunk sans ingress-filtering',
        'Ce port accepte uniquement les trames VLAN taggées mais ingress-filtering est désactivé. Continuer malgré ce risque ?',
      );
      if (!ok) return;
    }
    if (accessLike && pvid.text.trim() == '1') {
      final ok = await _confirm(
        'Port access sur VLAN 1',
        'Ce port est configuré comme access avec PVID 1. Vérifiez qu’il ne s’agit pas d’un oubli avant de continuer.',
      );
      if (!ok) return;
    }
    if (bpduGuard && !accessLike) {
      final ok = await _confirm(
        'BPDU Guard sur un port non access',
        'BPDU Guard peut bloquer le port si des BPDUs sont reçus. Il est généralement réservé aux vrais ports edge/access.',
      );
      if (!ok) return;
    }

    final id = widget.row['.id'];
    if (id == null) return;
    final data = <String, String>{
      'pvid': pvid.text.trim(),
      'frame-types': frame,
      'ingress-filtering': ingress ? 'yes' : 'no',
      'edge': edge,
      'point-to-point': pointToPoint,
      'bpdu-guard': bpduGuard ? 'yes' : 'no',
      'restricted-role': restrictedRole ? 'yes' : 'no',
      'restricted-tcn': restrictedTcn ? 'yes' : 'no',
      'comment': comment.text.trim(),
      if (horizon.text.trim().isNotEmpty) 'horizon': horizon.text.trim(),
      if (pathCost.text.trim().isNotEmpty) 'path-cost': pathCost.text.trim(),
      if (internalPathCost.text.trim().isNotEmpty)
        'internal-path-cost': internalPathCost.text.trim(),
    };

    setState(() => saving = true);
    try {
      await widget.service.set('/interface/bridge/port', id, data);
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

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.row['interface'] ?? 'Port bridge')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(widget.row['interface'] ?? '—'),
              subtitle: Text(
                'Bridge ${widget.row['bridge'] ?? '—'} • HW ${widget.row['hw'] ?? 'no'}',
              ),
            ),
          ),
          TextFormField(
            controller: pvid,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'PVID',
              helperText: '1 à 4094',
            ),
            validator: (v) => BridgeVlanValidator.validVlanId(v ?? '')
                ? null
                : 'PVID invalide',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: frame,
            decoration: const InputDecoration(labelText: 'Frame types'),
            items: const [
              'admit-all',
              'admit-only-vlan-tagged',
              'admit-only-untagged-and-priority-tagged',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => frame = v ?? 'admit-all'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ingress filtering'),
            subtitle: Text(
              trunkLike
                  ? 'Recommandé pour un trunk VLAN.'
                  : 'Vérifie l’appartenance VLAN en entrée.',
            ),
            value: ingress,
            onChanged: (v) => setState(() => ingress = v),
          ),
          const Divider(),
          DropdownButtonFormField<String>(
            value: edge,
            decoration: const InputDecoration(labelText: 'STP Edge'),
            items: const [
              'auto',
              'yes',
              'yes-discover',
              'no',
              'no-discover',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => edge = v ?? 'auto'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: pointToPoint,
            decoration: const InputDecoration(labelText: 'Point-to-point'),
            items: const [
              'auto',
              'yes',
              'no',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => pointToPoint = v ?? 'auto'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('BPDU Guard'),
            subtitle: const Text('À réserver aux vrais ports edge/access.'),
            value: bpduGuard,
            onChanged: (v) => setState(() => bpduGuard = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Restricted Role'),
            value: restrictedRole,
            onChanged: (v) => setState(() => restrictedRole = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Restricted TCN'),
            value: restrictedTcn,
            onChanged: (v) => setState(() => restrictedTcn = v),
          ),
          TextFormField(
            controller: horizon,
            decoration: const InputDecoration(
              labelText: 'Horizon',
              hintText: 'none ou valeur',
            ),
            validator: (v) => BridgeVlanValidator.validHorizon(v ?? '')
                ? null
                : 'Horizon invalide',
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: pathCost,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Path Cost'),
            validator: (v) => BridgeVlanValidator.validCost(v ?? '')
                ? null
                : 'Path Cost invalide',
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: internalPathCost,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Internal Path Cost'),
            validator: (v) => BridgeVlanValidator.validCost(v ?? '')
                ? null
                : 'Internal Path Cost invalide',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: comment,
            decoration: const InputDecoration(labelText: 'Commentaire'),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                trunkLike
                    ? 'Profil trunk : trames taggées uniquement. Vérifiez que le port est membre tagged des VLANs nécessaires.'
                    : accessLike
                    ? 'Profil access : les trames non taggées reçoivent le PVID choisi.'
                    : 'Profil hybride/admit-all : vérifiez soigneusement PVID et Bridge VLAN Table.',
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
    pvid.dispose();
    comment.dispose();
    horizon.dispose();
    pathCost.dispose();
    internalPathCost.dispose();
    super.dispose();
  }
}
