import 'package:flutter/material.dart';
import 'firewall_safety_analyzer.dart';
import 'firewall_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class RawRuleEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const RawRuleEditorScreen({super.key, required this.service, this.row});

  @override
  State<RawRuleEditorScreen> createState() => _RawRuleEditorScreenState();
}

class _RawRuleEditorScreenState extends State<RawRuleEditorScreen> {
  late final TextEditingController chain;
  late final TextEditingController srcAddress;
  late final TextEditingController dstAddress;
  late final TextEditingController dstPort;
  late final TextEditingController inInterface;
  late final TextEditingController comment;
  String action = 'accept';
  String protocol = '';
  bool enabled = true;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    chain = TextEditingController(text: r?['chain'] ?? 'prerouting');
    srcAddress = TextEditingController(text: r?['src-address'] ?? '');
    dstAddress = TextEditingController(text: r?['dst-address'] ?? '');
    dstPort = TextEditingController(text: r?['dst-port'] ?? '');
    inInterface = TextEditingController(text: r?['in-interface'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    action = r?['action'] ?? 'accept';
    protocol = r?['protocol'] ?? '';
    enabled = r?['disabled'] != 'true' && r?['disabled'] != 'yes';
  }

  Future<void> save() async {
    final error =
        FirewallInputValidator.chain(chain.text) ??
        FirewallInputValidator.ipOrCidrOrEmpty(
          srcAddress.text,
          label: 'Src Address',
        ) ??
        FirewallInputValidator.ipOrCidrOrEmpty(
          dstAddress.text,
          label: 'Dst Address',
        ) ??
        FirewallInputValidator.ports(dstPort.text, label: 'Dst Port');
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if ((action == 'drop' || action == 'notrack') &&
        srcAddress.text.trim().isEmpty &&
        dstAddress.text.trim().isEmpty &&
        inInterface.text.trim().isEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Règle RAW très large'),
              content: Text(
                'L’action $action sans source, destination ni interface peut '
                'affecter une grande partie du trafic avant Connection Tracking.',
              ),
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
    final values = <String, String>{
      'chain': chain.text.trim(),
      'action': action,
      'disabled': enabled ? 'no' : 'yes',
      if (protocol.isNotEmpty) 'protocol': protocol,
      if (srcAddress.text.trim().isNotEmpty)
        'src-address': srcAddress.text.trim(),
      if (dstAddress.text.trim().isNotEmpty)
        'dst-address': dstAddress.text.trim(),
      if (dstPort.text.trim().isNotEmpty) 'dst-port': dstPort.text.trim(),
      if (inInterface.text.trim().isNotEmpty)
        'in-interface': inInterface.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    final id = widget.row?['.id'];
    if (id == null) {
      await widget.service.add('/ip/firewall/raw', values);
    } else {
      await widget.service.set('/ip/firewall/raw', id, values);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.row == null ? 'Ajouter RAW' : 'Modifier RAW'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: chain,
          decoration: const InputDecoration(labelText: 'Chain'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: action,
          decoration: const InputDecoration(labelText: 'Action'),
          items: const [
            'accept',
            'drop',
            'jump',
            'log',
            'notrack',
            'passthrough',
            'return',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => action = v ?? 'accept'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: protocol,
          decoration: const InputDecoration(labelText: 'Protocole'),
          items: const ['', 'tcp', 'udp', 'icmp']
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.isEmpty ? 'Tous' : e),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => protocol = v ?? ''),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: srcAddress,
          decoration: const InputDecoration(labelText: 'Src Address'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: dstAddress,
          decoration: const InputDecoration(labelText: 'Dst Address'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: dstPort,
          decoration: const InputDecoration(labelText: 'Dst Port'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: inInterface,
          decoration: const InputDecoration(labelText: 'In Interface'),
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
          onPressed: save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Enregistrer'),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    chain.dispose();
    srcAddress.dispose();
    dstAddress.dispose();
    dstPort.dispose();
    inInterface.dispose();
    comment.dispose();
    super.dispose();
  }
}
