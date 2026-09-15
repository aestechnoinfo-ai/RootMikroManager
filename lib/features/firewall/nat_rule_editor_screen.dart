import 'package:flutter/material.dart';
import 'firewall_safety_analyzer.dart';
import 'firewall_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class NatRuleEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const NatRuleEditorScreen({super.key, required this.service, this.row});

  @override
  State<NatRuleEditorScreen> createState() => _NatRuleEditorScreenState();
}

class _NatRuleEditorScreenState extends State<NatRuleEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController chain;
  late final TextEditingController srcAddress;
  late final TextEditingController dstAddress;
  late final TextEditingController dstPort;
  late final TextEditingController inInterface;
  late final TextEditingController outInterface;
  late final TextEditingController toAddresses;
  late final TextEditingController toPorts;
  late final TextEditingController comment;
  String action = 'masquerade';
  String protocol = '';
  bool enabled = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    chain = TextEditingController(text: r?['chain'] ?? 'srcnat');
    srcAddress = TextEditingController(text: r?['src-address'] ?? '');
    dstAddress = TextEditingController(text: r?['dst-address'] ?? '');
    dstPort = TextEditingController(text: r?['dst-port'] ?? '');
    inInterface = TextEditingController(text: r?['in-interface'] ?? '');
    outInterface = TextEditingController(text: r?['out-interface'] ?? '');
    toAddresses = TextEditingController(text: r?['to-addresses'] ?? '');
    toPorts = TextEditingController(text: r?['to-ports'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    action = r?['action'] ?? 'masquerade';
    protocol = r?['protocol'] ?? '';
    enabled = r?['disabled'] != 'true' && r?['disabled'] != 'yes';
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || saving) return;
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
        FirewallInputValidator.ipv4RangeOrCidrOrEmpty(
          toAddresses.text,
          label: 'To Addresses',
        ) ??
        FirewallInputValidator.ports(toPorts.text, label: 'To Ports');
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final issues = FirewallSafetyAnalyzer.natRule(
      chain: chain.text.trim(),
      action: action,
      protocol: protocol,
      dstPort: dstPort.text.trim(),
      toAddresses: toAddresses.text.trim(),
      toPorts: toPorts.text.trim(),
    );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification NAT'),
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
      'disabled': enabled ? 'no' : 'yes',
      if (protocol.isNotEmpty) 'protocol': protocol,
      if (srcAddress.text.trim().isNotEmpty)
        'src-address': srcAddress.text.trim(),
      if (dstAddress.text.trim().isNotEmpty)
        'dst-address': dstAddress.text.trim(),
      if (dstPort.text.trim().isNotEmpty) 'dst-port': dstPort.text.trim(),
      if (inInterface.text.trim().isNotEmpty)
        'in-interface': inInterface.text.trim(),
      if (outInterface.text.trim().isNotEmpty)
        'out-interface': outInterface.text.trim(),
      if (toAddresses.text.trim().isNotEmpty)
        'to-addresses': toAddresses.text.trim(),
      if (toPorts.text.trim().isNotEmpty) 'to-ports': toPorts.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ip/firewall/nat', values);
      } else {
        await widget.service.set('/ip/firewall/nat', id, values);
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
      title: Text(widget.row == null ? 'Ajouter NAT' : 'Modifier NAT'),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: chain,
            decoration: const InputDecoration(labelText: 'Chain *'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Chain obligatoire' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
            value: action,
            decoration: const InputDecoration(labelText: 'Action'),
            items: const [
              'masquerade',
              'src-nat',
              'dst-nat',
              'redirect',
              'netmap',
              'accept',
              'jump',
              'return',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => action = v ?? 'masquerade'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
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
            controller: outInterface,
            decoration: const InputDecoration(labelText: 'Out Interface'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: toAddresses,
            decoration: const InputDecoration(labelText: 'To Addresses'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: toPorts,
            decoration: const InputDecoration(labelText: 'To Ports'),
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
    ),
  );

  @override
  void dispose() {
    chain.dispose();
    srcAddress.dispose();
    dstAddress.dispose();
    dstPort.dispose();
    inInterface.dispose();
    outInterface.dispose();
    toAddresses.dispose();
    toPorts.dispose();
    comment.dispose();
    super.dispose();
  }
}
