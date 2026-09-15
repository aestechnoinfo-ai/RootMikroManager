import 'package:flutter/material.dart';
import '../network/vpn_safety_analyzer.dart';
import '../network/vpn_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class WireGuardPeerEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  final String interfaceName;

  const WireGuardPeerEditorScreen({
    super.key,
    required this.service,
    required this.interfaceName,
    this.row,
  });

  @override
  State<WireGuardPeerEditorScreen> createState() =>
      _WireGuardPeerEditorScreenState();
}

class _WireGuardPeerEditorScreenState extends State<WireGuardPeerEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController publicKey;
  late final TextEditingController allowedAddress;
  late final TextEditingController endpointAddress;
  late final TextEditingController endpointPort;
  late final TextEditingController keepalive;
  late final TextEditingController comment;
  bool responder = false;
  bool enabled = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    publicKey = TextEditingController(text: r?['public-key'] ?? '');
    allowedAddress = TextEditingController(text: r?['allowed-address'] ?? '');
    endpointAddress = TextEditingController(text: r?['endpoint-address'] ?? '');
    endpointPort = TextEditingController(text: r?['endpoint-port'] ?? '');
    keepalive = TextEditingController(text: r?['persistent-keepalive'] ?? '25');
    comment = TextEditingController(text: r?['comment'] ?? '');
    responder = r?['responder'] == 'yes' || r?['responder'] == 'true';
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
  }

  Future<void> save() async {
    if (saving) return;
    final error =
        VpnInputValidator.wireGuardKey(publicKey.text) ??
        VpnInputValidator.allowedAddresses(allowedAddress.text) ??
        VpnInputValidator.port(
          endpointPort.text,
          label: 'Endpoint Port',
          allowEmpty: true,
        ) ??
        VpnInputValidator.keepalive(keepalive.text);
    if (widget.interfaceName.isEmpty || error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.interfaceName.isEmpty
                ? 'Interface WireGuard obligatoire.'
                : error!,
          ),
        ),
      );
      return;
    }

    final port = endpointPort.text.trim().isEmpty
        ? null
        : int.parse(endpointPort.text.trim());
    final keep = int.tryParse(keepalive.text.trim()) ?? 0;
    final issues = VpnSafetyAnalyzer.wireGuardPeer(
      allowed: allowedAddress.text,
      endpoint: endpointAddress.text,
      keepalive: keep,
    );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification WireGuard'),
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

    final values = <String, String>{
      'interface': widget.interfaceName,
      'public-key': publicKey.text.trim(),
      'allowed-address': allowedAddress.text.trim(),
      'persistent-keepalive': '$keep',
      'responder': responder ? 'yes' : 'no',
      'disabled': enabled ? 'no' : 'yes',
      if (name.text.trim().isNotEmpty) 'name': name.text.trim(),
      if (endpointAddress.text.trim().isNotEmpty)
        'endpoint-address': endpointAddress.text.trim(),
      if (port != null) 'endpoint-port': '$port',
      'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/interface/wireguard/peers', values);
      } else {
        await widget.service.set('/interface/wireguard/peers', id, values);
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
      title: Text(widget.row == null ? 'Ajouter peer' : 'Modifier peer'),
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
          controller: publicKey,
          decoration: const InputDecoration(labelText: 'Public Key'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: allowedAddress,
          decoration: const InputDecoration(
            labelText: 'Allowed Address',
            hintText: '10.10.10.2/32',
            helperText: 'Les plages ne doivent pas se chevaucher entre peers.',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: endpointAddress,
          decoration: const InputDecoration(labelText: 'Endpoint Address'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: endpointPort,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Endpoint Port'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: keepalive,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Persistent Keepalive',
            helperText: '25 secondes est courant pour un peer derrière NAT.',
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Responder'),
          value: responder,
          onChanged: (v) => setState(() => responder = v),
        ),
        TextField(
          controller: comment,
          decoration: const InputDecoration(labelText: 'Commentaire'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Activé'),
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
    publicKey.dispose();
    allowedAddress.dispose();
    endpointAddress.dispose();
    endpointPort.dispose();
    keepalive.dispose();
    comment.dispose();
    super.dispose();
  }
}
