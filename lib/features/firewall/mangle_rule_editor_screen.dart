import 'package:flutter/material.dart';
import 'firewall_safety_analyzer.dart';
import 'firewall_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class MangleRuleEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const MangleRuleEditorScreen({super.key, required this.service, this.row});

  @override
  State<MangleRuleEditorScreen> createState() => _MangleRuleEditorScreenState();
}

class _MangleRuleEditorScreenState extends State<MangleRuleEditorScreen> {
  late final TextEditingController chain;
  late final TextEditingController newMark;
  late final TextEditingController newTtl;
  late final TextEditingController srcAddress;
  late final TextEditingController dstAddress;
  late final TextEditingController dstPort;
  late final TextEditingController inInterface;
  late final TextEditingController outInterface;
  late final TextEditingController comment;
  String action = 'mark-packet';
  String protocol = '';
  bool passthrough = true;
  bool enabled = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    chain = TextEditingController(text: r?['chain'] ?? 'prerouting');
    newMark = TextEditingController(
      text:
          r?['new-packet-mark'] ??
          r?['new-connection-mark'] ??
          r?['new-routing-mark'] ??
          '',
    );
    newTtl = TextEditingController(text: r?['new-ttl'] ?? 'set:1');
    srcAddress = TextEditingController(text: r?['src-address'] ?? '');
    dstAddress = TextEditingController(text: r?['dst-address'] ?? '');
    dstPort = TextEditingController(text: r?['dst-port'] ?? '');
    inInterface = TextEditingController(text: r?['in-interface'] ?? '');
    outInterface = TextEditingController(text: r?['out-interface'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    action = r?['action'] ?? 'mark-packet';
    protocol = r?['protocol'] ?? '';
    passthrough = r?['passthrough'] != 'false' && r?['passthrough'] != 'no';
    enabled = r?['disabled'] != 'true' && r?['disabled'] != 'yes';
  }

  String markKey() {
    if (action == 'mark-connection') return 'new-connection-mark';
    if (action == 'mark-routing') return 'new-routing-mark';
    return 'new-packet-mark';
  }

  Future<void> save() async {
    if (saving) return;
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
        FirewallInputValidator.ports(dstPort.text, label: 'Dst Port') ??
        (action.startsWith('mark-')
            ? FirewallInputValidator.mark(newMark.text)
            : null);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final issues = FirewallSafetyAnalyzer.mangleRule(
      action: action,
      chain: chain.text.trim(),
      newMark: newMark.text.trim(),
    );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification Mangle'),
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
      'chain': chain.text.trim(),
      'action': action,
      'passthrough': passthrough ? 'yes' : 'no',
      'disabled': enabled ? 'no' : 'yes',
      if (protocol.isNotEmpty) 'protocol': protocol,
      if (newMark.text.trim().isNotEmpty) markKey(): newMark.text.trim(),
      if (action == 'change-ttl' && newTtl.text.trim().isNotEmpty)
        'new-ttl': newTtl.text.trim(),
      if (srcAddress.text.trim().isNotEmpty)
        'src-address': srcAddress.text.trim(),
      if (dstAddress.text.trim().isNotEmpty)
        'dst-address': dstAddress.text.trim(),
      if (dstPort.text.trim().isNotEmpty) 'dst-port': dstPort.text.trim(),
      if (inInterface.text.trim().isNotEmpty)
        'in-interface': inInterface.text.trim(),
      if (outInterface.text.trim().isNotEmpty)
        'out-interface': outInterface.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ip/firewall/mangle', values);
      } else {
        await widget.service.set('/ip/firewall/mangle', id, values);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.row == null ? 'Ajouter Mangle' : 'Modifier Mangle'),
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
            'mark-packet',
            'mark-connection',
            'mark-routing',
            'change-dscp',
            'change-mss',
            'change-ttl',
            'accept',
            'drop',
            'jump',
            'log',
            'passthrough',
            'return',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => action = v ?? action),
        ),
        const SizedBox(height: 10),
        if (action.startsWith('mark-'))
          TextField(
            controller: newMark,
            decoration: const InputDecoration(labelText: 'New Mark'),
          ),
        if (action == 'change-ttl')
          TextField(
            controller: newTtl,
            decoration: const InputDecoration(
              labelText: 'New TTL',
              hintText: 'set:1',
            ),
          ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: protocol,
          decoration: const InputDecoration(labelText: 'Protocole'),
          items: const ['', 'tcp', 'udp', 'icmp', 'gre']
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
          controller: outInterface,
          decoration: const InputDecoration(labelText: 'Out Interface'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: comment,
          decoration: const InputDecoration(labelText: 'Commentaire'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Passthrough'),
          value: passthrough,
          onChanged: (v) => setState(() => passthrough = v),
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
    chain.dispose();
    newMark.dispose();
    newTtl.dispose();
    srcAddress.dispose();
    dstAddress.dispose();
    dstPort.dispose();
    inInterface.dispose();
    outInterface.dispose();
    comment.dispose();
    super.dispose();
  }
}
