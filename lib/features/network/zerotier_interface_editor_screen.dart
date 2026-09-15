import 'package:flutter/material.dart';
import 'vpn_safety_analyzer.dart';
import 'vpn_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class ZeroTierInterfaceEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const ZeroTierInterfaceEditorScreen({
    super.key,
    required this.service,
    this.row,
  });
  @override
  State<ZeroTierInterfaceEditorScreen> createState() => _State();
}

class _State extends State<ZeroTierInterfaceEditorScreen> {
  late final TextEditingController name, network, comment;
  bool allowDefault = false,
      allowGlobal = false,
      allowManaged = true,
      enabled = true,
      saving = false;
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    network = TextEditingController(text: r?['network'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    allowDefault = r?['allow-default'] == 'yes';
    allowGlobal = r?['allow-global'] == 'yes';
    allowManaged = r?['allow-managed'] != 'no';
    enabled = r?['disabled'] != 'yes';
  }

  Future<void> save() async {
    if (saving) return;
    final error =
        VpnInputValidator.name(name.text, label: 'Nom interface') ??
        VpnInputValidator.zeroTierNetworkId(network.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final issues = VpnSafetyAnalyzer.zeroTier(
      allowDefault: allowDefault,
      allowGlobal: allowGlobal,
    );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification ZeroTier'),
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
    final v = {
      'name': name.text.trim(),
      'network': network.text.trim(),
      'allow-default': allowDefault ? 'yes' : 'no',
      'allow-global': allowGlobal ? 'yes' : 'no',
      'allow-managed': allowManaged ? 'yes' : 'no',
      'disabled': enabled ? 'no' : 'yes',
      'comment': comment.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/zerotier/interface', v);
      else
        await widget.service.set('/zerotier/interface', id, v);
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
        widget.row == null ? 'Ajouter ZeroTier' : 'Modifier ZeroTier',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nom interface'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: network,
          decoration: const InputDecoration(labelText: 'Network ID'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow managed'),
          subtitle: const Text(
            'Autoriser adresses et routes gérées par le contrôleur.',
          ),
          value: allowManaged,
          onChanged: (v) => setState(() => allowManaged = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow global'),
          subtitle: const Text(
            'Autoriser le chevauchement avec l’espace IP public.',
          ),
          value: allowGlobal,
          onChanged: (v) => setState(() => allowGlobal = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow default'),
          subtitle: const Text('Peut remplacer la route par défaut.'),
          value: allowDefault,
          onChanged: (v) => setState(() => allowDefault = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Activée'),
          value: enabled,
          onChanged: (v) => setState(() => enabled = v),
        ),
        TextField(
          controller: comment,
          decoration: const InputDecoration(labelText: 'Commentaire'),
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
    name.dispose();
    network.dispose();
    comment.dispose();
    super.dispose();
  }
}
