import 'package:flutter/material.dart';
import 'network_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class DhcpNetworkEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const DhcpNetworkEditorScreen({super.key, required this.service, this.row});

  @override
  State<DhcpNetworkEditorScreen> createState() =>
      _DhcpNetworkEditorScreenState();
}

class _DhcpNetworkEditorScreenState extends State<DhcpNetworkEditorScreen> {
  late final TextEditingController address;
  late final TextEditingController gateway;
  late final TextEditingController dnsServer;
  late final TextEditingController domain;
  late final TextEditingController ntpServer;
  late final TextEditingController winsServer;
  late final TextEditingController comment;
  bool dnsNone = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    address = TextEditingController(text: r?['address'] ?? '');
    gateway = TextEditingController(text: r?['gateway'] ?? '');
    dnsServer = TextEditingController(text: r?['dns-server'] ?? '');
    domain = TextEditingController(text: r?['domain'] ?? '');
    ntpServer = TextEditingController(text: r?['ntp-server'] ?? '');
    winsServer = TextEditingController(text: r?['wins-server'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    dnsNone = r?['dns-none'] == 'yes' || r?['dns-none'] == 'true';
  }

  Future<void> save() async {
    if (saving) return;
    final error =
        NetworkInputValidator.ipv4Cidr(address.text, label: 'Réseau DHCP') ??
        NetworkInputValidator.ipv4OrEmpty(gateway.text, label: 'Gateway') ??
        NetworkInputValidator.ipv4List(dnsServer.text, label: 'Serveurs DNS') ??
        NetworkInputValidator.ipv4List(ntpServer.text, label: 'Serveurs NTP') ??
        NetworkInputValidator.ipv4List(winsServer.text, label: 'Serveurs WINS');
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => saving = true);

    final values = <String, String>{
      'address': address.text.trim(),
      if (gateway.text.trim().isNotEmpty) 'gateway': gateway.text.trim(),
      if (dnsServer.text.trim().isNotEmpty) 'dns-server': dnsServer.text.trim(),
      if (domain.text.trim().isNotEmpty) 'domain': domain.text.trim(),
      if (ntpServer.text.trim().isNotEmpty) 'ntp-server': ntpServer.text.trim(),
      if (winsServer.text.trim().isNotEmpty)
        'wins-server': winsServer.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
      'dns-none': dnsNone ? 'yes' : 'no',
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ip/dhcp-server/network', values);
      } else {
        await widget.service.set('/ip/dhcp-server/network', id, values);
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
        widget.row == null ? 'Ajouter réseau DHCP' : 'Modifier réseau DHCP',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: address,
          decoration: const InputDecoration(
            labelText: 'Réseau',
            hintText: '192.168.88.0/24',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: gateway,
          decoration: const InputDecoration(
            labelText: 'Gateway',
            hintText: '192.168.88.1',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: dnsServer,
          decoration: const InputDecoration(
            labelText: 'DNS Server',
            hintText: '192.168.88.1,1.1.1.1',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: domain,
          decoration: const InputDecoration(labelText: 'Domain'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: ntpServer,
          decoration: const InputDecoration(labelText: 'NTP Server'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: winsServer,
          decoration: const InputDecoration(labelText: 'WINS Server'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: comment,
          decoration: const InputDecoration(labelText: 'Commentaire'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ne pas distribuer de DNS'),
          value: dnsNone,
          onChanged: (v) => setState(() => dnsNone = v),
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
    gateway.dispose();
    dnsServer.dispose();
    domain.dispose();
    ntpServer.dispose();
    winsServer.dispose();
    comment.dispose();
    super.dispose();
  }
}
