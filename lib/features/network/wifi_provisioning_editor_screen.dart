import 'package:flutter/material.dart';
import 'wifi_wireless_safety_analyzer.dart';
import 'wifi_wireless_validator.dart';
import '../../core/routeros/routeros_service.dart';

class WifiProvisioningEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const WifiProvisioningEditorScreen({
    super.key,
    required this.service,
    this.row,
  });
  @override
  State<WifiProvisioningEditorScreen> createState() => _S();
}

class _S extends State<WifiProvisioningEditorScreen> {
  late final TextEditingController radio,
      supported,
      identity,
      master,
      slave,
      nameFormat,
      namePrefix,
      comment;
  String action = 'create-enabled';
  bool saving = false, enabled = true;
  @override
  void initState() {
    super.initState();
    final r = widget.row ?? {};
    radio = TextEditingController(text: r['radio-mac'] ?? '');
    supported = TextEditingController(text: r['supported-bands'] ?? '');
    identity = TextEditingController(text: r['identity-regexp'] ?? '');
    master = TextEditingController(text: r['master-configuration'] ?? '');
    slave = TextEditingController(text: r['slave-configurations'] ?? '');
    nameFormat = TextEditingController(text: r['name-format'] ?? '');
    namePrefix = TextEditingController(text: r['name-prefix'] ?? '');
    comment = TextEditingController(text: r['comment'] ?? '');
    action = r['action'] ?? 'create-enabled';
    enabled = r['disabled'] != 'yes';
  }

  Future<void> save() async {
    if (saving) return;
    final error = WifiWirelessValidator.provisioningMac(radio.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final issues = WifiWirelessSafetyAnalyzer.provisioning(
      action: action,
      radioMac: radio.text,
      supportedBands: supported.text,
      identityRegexp: identity.text,
      masterConfiguration: master.text,
    );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification Provisioning'),
              content: Text(issues.map((e) => '• ${e.message}').join('\n\n')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Revoir'),
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
    final v = <String, String>{
      'action': action,
      'master-configuration': master.text.trim(),
      'disabled': enabled ? 'no' : 'yes',
      if (radio.text.trim().isNotEmpty) 'radio-mac': radio.text.trim(),
      if (supported.text.trim().isNotEmpty)
        'supported-bands': supported.text.trim(),
      if (identity.text.trim().isNotEmpty)
        'identity-regexp': identity.text.trim(),
      if (slave.text.trim().isNotEmpty)
        'slave-configurations': slave.text.trim(),
      if (nameFormat.text.trim().isNotEmpty)
        'name-format': nameFormat.text.trim(),
      if (namePrefix.text.trim().isNotEmpty)
        'name-prefix': namePrefix.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/interface/wifi/provisioning', v);
      else
        await widget.service.set('/interface/wifi/provisioning', id, v);
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
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null ? 'Ajouter provisioning' : 'Modifier provisioning',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(isExpanded: true, 
          value: action,
          decoration: const InputDecoration(labelText: 'Action'),
          items: const [
            'create-enabled',
            'create-disabled',
            'create-dynamic',
            'none',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => action = v ?? 'create-enabled'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: master,
          decoration: const InputDecoration(labelText: 'Master configuration'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: slave,
          decoration: const InputDecoration(
            labelText: 'Slave configurations',
            hintText: 'profil1,profil2',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: radio,
          decoration: const InputDecoration(labelText: 'Radio MAC'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: supported,
          decoration: const InputDecoration(labelText: 'Supported bands'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: identity,
          decoration: const InputDecoration(labelText: 'Identity regexp'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: nameFormat,
          decoration: const InputDecoration(labelText: 'Name format'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: namePrefix,
          decoration: const InputDecoration(labelText: 'Name prefix'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: comment,
          decoration: const InputDecoration(labelText: 'Commentaire'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Règle activée'),
          value: enabled,
          onChanged: (v) => setState(() => enabled = v),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Les règles de provisioning sont évaluées dans l’ordre. Une règle trop générale placée en premier peut capturer les CAPs destinés aux règles suivantes.',
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
  );
  @override
  void dispose() {
    for (final x in [
      radio,
      supported,
      identity,
      master,
      slave,
      nameFormat,
      namePrefix,
      comment,
    ])
      x.dispose();
    super.dispose();
  }
}
