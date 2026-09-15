import 'package:flutter/material.dart';
import 'dhcp_dns_safety_analyzer.dart';
import 'network_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class DnsSettingsScreen extends StatefulWidget {
  final RouterOsService service;
  const DnsSettingsScreen({super.key, required this.service});

  @override
  State<DnsSettingsScreen> createState() => _DnsSettingsScreenState();
}

class _DnsSettingsScreenState extends State<DnsSettingsScreen> {
  final servers = TextEditingController();
  final dohServer = TextEditingController();
  final cacheSize = TextEditingController();
  final cacheMaxTtl = TextEditingController();
  final maxQueries = TextEditingController();
  final maxTcpSessions = TextEditingController();
  final maxUdpPacketSize = TextEditingController();
  bool allowRemoteRequests = false;
  bool verifyDohCertificate = false;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final row = await widget.service.dnsSettings();
    servers.text = row['servers'] ?? '';
    dohServer.text = row['use-doh-server'] ?? '';
    cacheSize.text = row['cache-size'] ?? '2048KiB';
    cacheMaxTtl.text = row['cache-max-ttl'] ?? '1w';
    maxQueries.text = row['max-concurrent-queries'] ?? '100';
    maxTcpSessions.text = row['max-concurrent-tcp-sessions'] ?? '20';
    maxUdpPacketSize.text = row['max-udp-packet-size'] ?? '4096';
    allowRemoteRequests =
        row['allow-remote-requests'] == 'yes' ||
        row['allow-remote-requests'] == 'true';
    verifyDohCertificate =
        row['verify-doh-cert'] == 'yes' || row['verify-doh-cert'] == 'true';
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving) return;
    final error =
        NetworkInputValidator.dnsServerList(
          servers.text,
          label: 'Serveurs DNS',
        ) ??
        (dohServer.text.trim().isEmpty
            ? null
            : NetworkInputValidator.httpUrl(
                dohServer.text,
                label: 'Serveur DoH',
              )) ??
        NetworkInputValidator.positiveInteger(
          maxQueries.text,
          label: 'Max Concurrent Queries',
        ) ??
        NetworkInputValidator.positiveInteger(
          maxTcpSessions.text,
          label: 'Max Concurrent TCP Sessions',
        ) ??
        NetworkInputValidator.positiveInteger(
          maxUdpPacketSize.text,
          label: 'Max UDP Packet Size',
          min: 50,
          max: 65507,
        );
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final issues = DhcpDnsSafetyAnalyzer.dnsResolver(
      allowRemoteRequests: allowRemoteRequests,
      dohServer: dohServer.text,
      verifyDohCertificate: verifyDohCertificate,
    );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification sécurité DNS'),
              content: Text(issues.map((e) => '• ${e.message}').join('\n\n')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Revoir'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Enregistrer quand même'),
                ),
              ],
            ),
          ) ??
          false;
      if (!ok) return;
    }

    setState(() => saving = true);
    try {
      await widget.service.setDnsSettings({
        'servers': servers.text.trim(),
        'allow-remote-requests': allowRemoteRequests ? 'yes' : 'no',
        if (dohServer.text.trim().isNotEmpty)
          'use-doh-server': dohServer.text.trim(),
        if (dohServer.text.trim().isEmpty) 'use-doh-server': '',
        'verify-doh-cert': verifyDohCertificate ? 'yes' : 'no',
        if (cacheSize.text.trim().isNotEmpty)
          'cache-size': cacheSize.text.trim(),
        if (cacheMaxTtl.text.trim().isNotEmpty)
          'cache-max-ttl': cacheMaxTtl.text.trim(),
        if (maxQueries.text.trim().isNotEmpty)
          'max-concurrent-queries': maxQueries.text.trim(),
        if (maxTcpSessions.text.trim().isNotEmpty)
          'max-concurrent-tcp-sessions': maxTcpSessions.text.trim(),
        if (maxUdpPacketSize.text.trim().isNotEmpty)
          'max-udp-packet-size': maxUdpPacketSize.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration DNS enregistrée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configuration DNS')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: servers,
                decoration: const InputDecoration(
                  labelText: 'Serveurs DNS',
                  hintText: '1.1.1.1,8.8.8.8',
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow Remote Requests'),
                subtitle: const Text(
                  'Autorise les clients à utiliser le routeur comme cache DNS. '
                  'Limiter TCP/UDP 53 aux réseaux de confiance dans le firewall.',
                ),
                value: allowRemoteRequests,
                onChanged: (v) => setState(() => allowRemoteRequests = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dohServer,
                decoration: const InputDecoration(
                  labelText: 'DoH Server',
                  hintText: 'https://dns.example/dns-query',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vérifier le certificat DoH'),
                value: verifyDohCertificate,
                onChanged: (v) => setState(() => verifyDohCertificate = v),
              ),
              const Divider(height: 28),
              TextField(
                controller: cacheSize,
                decoration: const InputDecoration(labelText: 'Cache Size'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cacheMaxTtl,
                decoration: const InputDecoration(labelText: 'Cache Max TTL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: maxQueries,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Concurrent Queries',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: maxTcpSessions,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Concurrent TCP Sessions',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: maxUdpPacketSize,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max UDP Packet Size',
                ),
              ),
              const SizedBox(height: 16),
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
    servers.dispose();
    dohServer.dispose();
    cacheSize.dispose();
    cacheMaxTtl.dispose();
    maxQueries.dispose();
    maxTcpSessions.dispose();
    maxUdpPacketSize.dispose();
    super.dispose();
  }
}
