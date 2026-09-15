import 'package:flutter/material.dart';
import 'network_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class DhcpLeaseEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const DhcpLeaseEditorScreen({super.key, required this.service, this.row});

  @override
  State<DhcpLeaseEditorScreen> createState() => _DhcpLeaseEditorScreenState();
}

class _DhcpLeaseEditorScreenState extends State<DhcpLeaseEditorScreen> {
  late final TextEditingController address;
  late final TextEditingController macAddress;
  late final TextEditingController clientId;
  late final TextEditingController leaseTime;
  late final TextEditingController rateLimit;
  late final TextEditingController comment;
  String server = 'all';
  bool blockAccess = false;
  bool loading = true;
  bool saving = false;
  List<String> servers = ['all'];

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    address = TextEditingController(text: r?['address'] ?? '');
    macAddress = TextEditingController(text: r?['mac-address'] ?? '');
    clientId = TextEditingController(text: r?['client-id'] ?? '');
    leaseTime = TextEditingController(text: r?['lease-time'] ?? '0s');
    rateLimit = TextEditingController(text: r?['rate-limit'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    server = r?['server'] ?? 'all';
    blockAccess = r?['block-access'] == 'yes' || r?['block-access'] == 'true';
    loadServers();
  }

  Future<void> loadServers() async {
    final rows = await widget.service.dhcpServers();
    servers = [
      'all',
      ...rows.map((e) => (e['name'] ?? '').trim()).where((e) => e.isNotEmpty),
    ];
    if (!servers.contains(server)) servers.add(server);
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving) return;
    final error =
        NetworkInputValidator.ipv4(address.text, label: 'Adresse IP') ??
        NetworkInputValidator.mac(macAddress.text) ??
        NetworkInputValidator.routerOsDuration(
          leaseTime.text,
          label: 'Lease Time',
          allowEmpty: true,
        );
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => saving = true);
    final values = <String, String>{
      'address': address.text.trim(),
      'mac-address': macAddress.text.trim(),
      'server': server,
      'block-access': blockAccess ? 'yes' : 'no',
      if (clientId.text.trim().isNotEmpty) 'client-id': clientId.text.trim(),
      if (leaseTime.text.trim().isNotEmpty) 'lease-time': leaseTime.text.trim(),
      if (rateLimit.text.trim().isNotEmpty) 'rate-limit': rateLimit.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ip/dhcp-server/lease', values);
      } else {
        await widget.service.set('/ip/dhcp-server/lease', id, values);
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
        widget.row == null ? 'Ajouter bail statique' : 'Modifier bail DHCP',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Adresse IP'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: macAddress,
                decoration: const InputDecoration(labelText: 'Adresse MAC'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(isExpanded: true, 
                value: servers.contains(server) ? server : 'all',
                decoration: const InputDecoration(labelText: 'Serveur'),
                items: servers
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => server = v ?? 'all'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clientId,
                decoration: const InputDecoration(labelText: 'Client ID'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: leaseTime,
                decoration: const InputDecoration(
                  labelText: 'Lease Time',
                  hintText: '0s = sans expiration',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rateLimit,
                decoration: const InputDecoration(
                  labelText: 'Rate Limit',
                  hintText: '10M/10M',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: comment,
                decoration: const InputDecoration(labelText: 'Commentaire'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bloquer l’accès'),
                value: blockAccess,
                onChanged: (v) => setState(() => blockAccess = v),
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
    address.dispose();
    macAddress.dispose();
    clientId.dispose();
    leaseTime.dispose();
    rateLimit.dispose();
    comment.dispose();
    super.dispose();
  }
}
