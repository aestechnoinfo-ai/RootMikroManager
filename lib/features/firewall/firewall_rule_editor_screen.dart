import 'package:flutter/material.dart';
import 'firewall_safety_analyzer.dart';
import 'firewall_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class FirewallRuleEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final String path;
  final String title;
  final Map<String, String>? row;

  const FirewallRuleEditorScreen({
    super.key,
    required this.service,
    required this.path,
    required this.title,
    this.row,
  });

  @override
  State<FirewallRuleEditorScreen> createState() =>
      _FirewallRuleEditorScreenState();
}

class _FirewallRuleEditorScreenState extends State<FirewallRuleEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController chain;
  late final TextEditingController action;
  late final TextEditingController srcAddress;
  late final TextEditingController dstAddress;
  late final TextEditingController srcPort;
  late final TextEditingController dstPort;
  late final TextEditingController inInterface;
  late final TextEditingController outInterface;
  late final TextEditingController comment;
  String protocol = '';
  bool enabled = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final row = widget.row;
    chain = TextEditingController(
      text:
          row?['chain'] ??
          (widget.path.endsWith('/nat') ? 'srcnat' : 'forward'),
    );
    action = TextEditingController(
      text:
          row?['action'] ??
          (widget.path.endsWith('/nat') ? 'masquerade' : 'accept'),
    );
    srcAddress = TextEditingController(text: row?['src-address'] ?? '');
    dstAddress = TextEditingController(text: row?['dst-address'] ?? '');
    srcPort = TextEditingController(text: row?['src-port'] ?? '');
    dstPort = TextEditingController(text: row?['dst-port'] ?? '');
    inInterface = TextEditingController(text: row?['in-interface'] ?? '');
    outInterface = TextEditingController(text: row?['out-interface'] ?? '');
    comment = TextEditingController(text: row?['comment'] ?? '');
    protocol = row?['protocol'] ?? '';
    enabled = row?['disabled'] != 'true' && row?['disabled'] != 'yes';
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
        FirewallInputValidator.ports(srcPort.text, label: 'Src Port') ??
        FirewallInputValidator.ports(dstPort.text, label: 'Dst Port');
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final issues = widget.path.endsWith('/nat')
        ? FirewallSafetyAnalyzer.natRule(
            chain: chain.text.trim(),
            action: action.text.trim(),
            protocol: protocol,
            dstPort: dstPort.text.trim(),
            toAddresses: '',
            toPorts: '',
          )
        : FirewallSafetyAnalyzer.filterRule(
            chain: chain.text.trim(),
            action: action.text.trim(),
            protocol: protocol,
            srcAddress: srcAddress.text.trim(),
            dstPort: dstPort.text.trim(),
            inInterface: inInterface.text.trim(),
            connectionState: '',
          );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification Firewall'),
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
      'action': action.text.trim(),
      'disabled': enabled ? 'no' : 'yes',
      if (protocol.isNotEmpty) 'protocol': protocol,
      if (srcAddress.text.trim().isNotEmpty)
        'src-address': srcAddress.text.trim(),
      if (dstAddress.text.trim().isNotEmpty)
        'dst-address': dstAddress.text.trim(),
      if (srcPort.text.trim().isNotEmpty) 'src-port': srcPort.text.trim(),
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
        await widget.service.add(widget.path, values);
      } else {
        await widget.service.set(widget.path, id, values);
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
      title: Text(
        widget.row == null
            ? 'Ajouter — ${widget.title}'
            : 'Modifier — ${widget.title}',
      ),
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
          TextFormField(
            controller: action,
            decoration: const InputDecoration(labelText: 'Action *'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Action obligatoire' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: protocol,
            decoration: const InputDecoration(labelText: 'Protocole'),
            items: const ['', 'tcp', 'udp', 'icmp', 'gre', 'ipsec-esp']
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
            decoration: const InputDecoration(labelText: 'Src address'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: dstAddress,
            decoration: const InputDecoration(labelText: 'Dst address'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: srcPort,
            decoration: const InputDecoration(labelText: 'Src port'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: dstPort,
            decoration: const InputDecoration(labelText: 'Dst port'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: inInterface,
            decoration: const InputDecoration(labelText: 'In interface'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: outInterface,
            decoration: const InputDecoration(labelText: 'Out interface'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: comment,
            maxLines: 2,
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
    action.dispose();
    srcAddress.dispose();
    dstAddress.dispose();
    srcPort.dispose();
    dstPort.dispose();
    inInterface.dispose();
    outInterface.dispose();
    comment.dispose();
    super.dispose();
  }
}
