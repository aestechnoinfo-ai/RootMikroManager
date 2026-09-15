import 'package:flutter/material.dart';
import '../network/vpn_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class WireGuardInterfaceEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const WireGuardInterfaceEditorScreen({
    super.key,
    required this.service,
    this.row,
  });

  @override
  State<WireGuardInterfaceEditorScreen> createState() =>
      _WireGuardInterfaceEditorScreenState();
}

class _WireGuardInterfaceEditorScreenState
    extends State<WireGuardInterfaceEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController listenPort;
  late final TextEditingController mtu;
  late final TextEditingController comment;
  bool enabled = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? 'wg1');
    listenPort = TextEditingController(text: r?['listen-port'] ?? '13231');
    mtu = TextEditingController(text: r?['mtu'] ?? '1420');
    comment = TextEditingController(text: r?['comment'] ?? '');
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
  }

  Future<void> save() async {
    if (saving) return;
    final error =
        VpnInputValidator.name(name.text, label: 'Nom') ??
        VpnInputValidator.port(listenPort.text, label: 'Listen Port') ??
        VpnInputValidator.mtu(mtu.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final port = int.parse(listenPort.text.trim());
    final parsedMtu = int.parse(mtu.text.trim());

    setState(() => saving = true);

    final values = <String, String>{
      'name': name.text.trim(),
      'listen-port': '$port',
      'mtu': '$parsedMtu',
      'disabled': enabled ? 'no' : 'yes',
      'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/interface/wireguard', values);
      } else {
        await widget.service.set('/interface/wireguard', id, values);
      }
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
      title: Text(
        widget.row == null
            ? 'Ajouter interface WireGuard'
            : 'Modifier interface WireGuard',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: listenPort,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Listen Port',
            hintText: '13231',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: mtu,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'MTU', hintText: '1420'),
        ),
        const SizedBox(height: 10),
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
    listenPort.dispose();
    mtu.dispose();
    comment.dispose();
    super.dispose();
  }
}
