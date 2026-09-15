import 'package:flutter/material.dart';
import 'wifi_wireless_safety_analyzer.dart';
import 'wifi_wireless_validator.dart';
import '../../core/routeros/routeros_service.dart';
import 'wifi_profile_kind.dart';

class WifiProfileEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final WifiProfileKind kind;
  final Map<String, String>? row;
  const WifiProfileEditorScreen({
    super.key,
    required this.service,
    required this.kind,
    this.row,
  });
  @override
  State<WifiProfileEditorScreen> createState() => _S();
}

class _S extends State<WifiProfileEditorScreen> {
  late final Map<String, TextEditingController> c;
  bool saving = false;
  String auth = '';
  @override
  void initState() {
    super.initState();
    final r = widget.row ?? {};
    c = {
      for (final k in [
        'name',
        'ssid',
        'country',
        'mode',
        'band',
        'frequency',
        'width',
        'passphrase',
        'vlan-id',
        'bridge',
        'comment',
      ])
        k: TextEditingController(text: r[k] ?? ''),
    };
    auth = r['authentication-types'] ?? '';
  }

  List<String> get fields => switch (widget.kind) {
    WifiProfileKind.configuration => [
      'name',
      'ssid',
      'country',
      'mode',
      'comment',
    ],
    WifiProfileKind.channel => [
      'name',
      'band',
      'frequency',
      'width',
      'comment',
    ],
    WifiProfileKind.security => ['name', 'passphrase', 'comment'],
    WifiProfileKind.datapath => ['name', 'bridge', 'vlan-id', 'comment'],
  };
  String label(String k) =>
      {
        'name': 'Nom',
        'ssid': 'SSID',
        'country': 'Pays',
        'mode': 'Mode',
        'band': 'Bande',
        'frequency': 'Fréquence',
        'width': 'Largeur canal',
        'passphrase': 'Passphrase (écriture uniquement)',
        'vlan-id': 'VLAN ID',
        'bridge': 'Bridge',
        'comment': 'Commentaire',
      }[k] ??
      k;
  Future<void> save() async {
    if (saving) return;
    String? error = WifiWirelessValidator.name(c['name']!.text, label: 'Nom');
    if (error == null && widget.kind == WifiProfileKind.datapath) {
      error = WifiWirelessValidator.vlanOrEmpty(c['vlan-id']!.text);
    }
    if (error == null && widget.kind == WifiProfileKind.channel) {
      error = WifiWirelessValidator.frequencyOrEmpty(c['frequency']!.text);
    }
    if (error == null && widget.kind == WifiProfileKind.security) {
      error = WifiWirelessValidator.passphrase(
        c['passphrase']!.text,
        authentication: auth,
      );
    }
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (widget.kind == WifiProfileKind.security) {
      final issues = WifiWirelessSafetyAnalyzer.security(
        authentication: auth,
        passphrase: c['passphrase']!.text,
      );
      if (issues.isNotEmpty) {
        final ok =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Vérification sécurité Wi‑Fi'),
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
    }
    setState(() => saving = true);
    final v = <String, String>{};
    for (final k in fields) {
      final x = c[k]!.text.trim();
      if (x.isNotEmpty) v[k] = x;
    }
    if (widget.kind == WifiProfileKind.security && auth.isNotEmpty)
      v['authentication-types'] = auth;
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add(widget.kind.path, v);
      else
        await widget.service.set(widget.kind.path, id, v);
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
      title: Text(
        '${widget.row == null ? 'Ajouter' : 'Modifier'} ${widget.kind.label}',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final k in fields) ...[
          if (widget.kind == WifiProfileKind.security && k == 'passphrase')
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Le secret est traité en écriture uniquement : RootMikroManager ne tente pas de relire ni d’afficher une passphrase existante.',
                ),
              ),
            ),
          TextField(
            controller: c[k],
            obscureText: k == 'passphrase',
            keyboardType: k == 'vlan-id' ? TextInputType.number : null,
            decoration: InputDecoration(labelText: label(k)),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.kind == WifiProfileKind.security)
          DropdownButtonFormField<String>(isExpanded: true, 
            value: auth.isEmpty ? null : auth,
            decoration: const InputDecoration(
              labelText: 'Authentication types',
            ),
            items: const [
              'wpa2-psk',
              'wpa3-psk',
              'wpa2-psk,wpa3-psk',
              'wpa2-eap',
              'wpa3-eap',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => auth = v ?? ''),
          ),
        if (widget.kind == WifiProfileKind.channel)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'La disponibilité des bandes, fréquences et largeurs dépend du matériel, du pays et du pilote WiFi.',
              ),
            ),
          ),
        if (widget.kind == WifiProfileKind.datapath)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Sur certains pilotes qcom-ac, le VLAN/PVID doit aussi être cohérent avec Bridge VLAN Filtering. Vérifiez le bridge avant activation en production.',
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
    for (final x in c.values) x.dispose();
    super.dispose();
  }
}
