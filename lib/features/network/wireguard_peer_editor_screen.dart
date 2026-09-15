import 'package:flutter/material.dart';
import 'vpn_safety_analyzer.dart';
import 'vpn_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class WireGuardPeerEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const WireGuardPeerEditorScreen({super.key, required this.service, this.row});
  @override
  State<WireGuardPeerEditorScreen> createState() => _State();
}

class _State extends State<WireGuardPeerEditorScreen> {
  late final TextEditingController publicKey,
      allowed,
      endpoint,
      port,
      keepalive,
      comment;
  String interface = '';
  bool enabled = true, responder = false, loading = true, saving = false;
  List<String> interfaces = [];
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    publicKey = TextEditingController(text: r?['public-key'] ?? '');
    allowed = TextEditingController(text: r?['allowed-address'] ?? '');
    endpoint = TextEditingController(text: r?['endpoint-address'] ?? '');
    port = TextEditingController(text: r?['endpoint-port'] ?? '');
    keepalive = TextEditingController(text: r?['persistent-keepalive'] ?? '0');
    comment = TextEditingController(text: r?['comment'] ?? '');
    interface = r?['interface'] ?? '';
    enabled = r?['disabled'] != 'yes';
    responder = r?['responder'] == 'yes';
    load();
  }

  Future<void> load() async {
    interfaces =
        (await widget.service.wireGuardInterfaces())
            .map((e) => e['name'] ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    if (interface.isNotEmpty && !interfaces.contains(interface))
      interfaces.add(interface);
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving) return;
    final error =
        VpnInputValidator.wireGuardKey(publicKey.text) ??
        VpnInputValidator.allowedAddresses(allowed.text) ??
        VpnInputValidator.port(
          port.text,
          label: 'Endpoint Port',
          allowEmpty: true,
        ) ??
        VpnInputValidator.keepalive(keepalive.text);
    if (interface.isEmpty || error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            interface.isEmpty ? 'Interface WireGuard obligatoire.' : error!,
          ),
        ),
      );
      return;
    }
    final ep =
        int.tryParse(port.text.trim().isEmpty ? '0' : port.text.trim()) ?? 0;
    final ka =
        int.tryParse(
          keepalive.text.trim().isEmpty ? '0' : keepalive.text.trim(),
        ) ??
        0;
    final issues = VpnSafetyAnalyzer.wireGuardPeer(
      allowed: allowed.text,
      endpoint: endpoint.text,
      keepalive: ka,
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
    final v = <String, String>{
      'interface': interface,
      'public-key': publicKey.text.trim(),
      'allowed-address': allowed.text.trim(),
      if (endpoint.text.trim().isNotEmpty)
        'endpoint-address': endpoint.text.trim(),
      if (ep > 0) 'endpoint-port': '$ep',
      'persistent-keepalive': '$ka',
      'disabled': enabled ? 'no' : 'yes',
      'responder': responder ? 'yes' : 'no',
      'comment': comment.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/interface/wireguard/peers', v);
      else
        await widget.service.set('/interface/wireguard/peers', id, v);
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
        widget.row == null
            ? 'Ajouter un peer WireGuard'
            : 'Modifier le peer WireGuard',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                value: interface.isEmpty ? null : interface,
                decoration: const InputDecoration(
                  labelText: 'Interface WireGuard',
                ),
                items: interfaces
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => interface = v ?? ''),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: publicKey,
                decoration: const InputDecoration(
                  labelText: 'Clé publique du peer',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: allowed,
                decoration: const InputDecoration(
                  labelText: 'Allowed Address',
                  hintText: '10.10.10.2/32,192.168.50.0/24',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: endpoint,
                decoration: const InputDecoration(
                  labelText: 'Endpoint address',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Endpoint port'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: keepalive,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Persistent keepalive (secondes)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Responder'),
                value: responder,
                onChanged: (v) => setState(() => responder = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activé'),
                value: enabled,
                onChanged: (v) => setState(() => enabled = v),
              ),
              TextField(
                controller: comment,
                decoration: const InputDecoration(labelText: 'Commentaire'),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'RootMikroManager ne demande ni n’affiche la clé privée. Les Allowed Addresses de peers d’une même interface ne doivent pas se chevaucher.',
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
    publicKey.dispose();
    allowed.dispose();
    endpoint.dispose();
    port.dispose();
    keepalive.dispose();
    comment.dispose();
    super.dispose();
  }
}
