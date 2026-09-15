import 'package:flutter/material.dart';
import 'dhcp_dns_safety_analyzer.dart';
import 'network_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class DhcpServerEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const DhcpServerEditorScreen({super.key, required this.service, this.row});

  @override
  State<DhcpServerEditorScreen> createState() => _DhcpServerEditorScreenState();
}

class _DhcpServerEditorScreenState extends State<DhcpServerEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController leaseTime;
  late final TextEditingController relay;
  String interfaceName = '';
  String addressPool = 'static-only';
  bool addArp = false;
  bool authoritative = true;
  bool enabled = true;
  bool loading = true;
  bool saving = false;

  List<String> interfaces = [];
  List<String> pools = ['static-only'];
  List<Map<String, String>> allServers = [];

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    leaseTime = TextEditingController(text: r?['lease-time'] ?? '30m');
    relay = TextEditingController(text: r?['relay'] ?? '0.0.0.0');
    interfaceName = r?['interface'] ?? '';
    addressPool = r?['address-pool'] ?? 'static-only';
    addArp = r?['add-arp'] == 'yes' || r?['add-arp'] == 'true';
    authoritative =
        r?['authoritative'] != 'no' && r?['authoritative'] != 'false';
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
    loadOptions();
  }

  Future<void> loadOptions() async {
    final result = await Future.wait([
      widget.service.interfaces(),
      widget.service.ipPools(),
      widget.service.dhcpServers(),
    ]);
    allServers = result[2];

    interfaces = result[0]
        .map((e) => (e['name'] ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    pools = [
      'static-only',
      ...result[1]
          .map((e) => (e['name'] ?? '').trim())
          .where((e) => e.isNotEmpty),
    ];

    if (interfaceName.isEmpty && interfaces.isNotEmpty) {
      interfaceName = interfaces.first;
    }
    if (!pools.contains(addressPool)) pools.add(addressPool);

    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving) return;
    final error =
        NetworkInputValidator.interfaceName(name.text) ??
        NetworkInputValidator.routerOsDuration(
          leaseTime.text,
          label: 'Lease Time',
        ) ??
        NetworkInputValidator.ipv4OrEmpty(relay.text, label: 'Relay');
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final issues = DhcpDnsSafetyAnalyzer.dhcpServer(
      interfaceName: interfaceName,
      addressPool: addressPool,
      relay: relay.text,
      servers: allServers,
      currentId: widget.row?['.id'],
    );
    final critical = issues.where((e) => e.critical).toList();
    if (critical.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(critical.map((e) => e.message).join('\n'))),
      );
      return;
    }
    setState(() => saving = true);

    final values = <String, String>{
      'name': name.text.trim(),
      'interface': interfaceName,
      'address-pool': addressPool,
      'lease-time': leaseTime.text.trim().isEmpty
          ? '30m'
          : leaseTime.text.trim(),
      'relay': relay.text.trim().isEmpty ? '0.0.0.0' : relay.text.trim(),
      'add-arp': addArp ? 'yes' : 'no',
      'authoritative': authoritative ? 'yes' : 'no',
      'disabled': enabled ? 'no' : 'yes',
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ip/dhcp-server', values);
      } else {
        await widget.service.set('/ip/dhcp-server', id, values);
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
        widget.row == null ? 'Ajouter serveur DHCP' : 'Modifier serveur DHCP',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(isExpanded: true, 
                value: interfaces.contains(interfaceName)
                    ? interfaceName
                    : null,
                decoration: const InputDecoration(labelText: 'Interface'),
                items: interfaces
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => interfaceName = v ?? interfaceName),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(isExpanded: true, 
                value: pools.contains(addressPool)
                    ? addressPool
                    : 'static-only',
                decoration: const InputDecoration(labelText: 'Address Pool'),
                items: pools
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => addressPool = v ?? 'static-only'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: leaseTime,
                decoration: const InputDecoration(
                  labelText: 'Lease Time',
                  hintText: '30m',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: relay,
                decoration: const InputDecoration(
                  labelText: 'Relay',
                  hintText: '0.0.0.0',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add ARP'),
                value: addArp,
                onChanged: (v) => setState(() => addArp = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Authoritative'),
                value: authoritative,
                onChanged: (v) => setState(() => authoritative = v),
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
    leaseTime.dispose();
    relay.dispose();
    super.dispose();
  }
}
