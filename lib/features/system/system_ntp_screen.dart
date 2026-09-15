import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemNtpScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemNtpScreen({super.key, required this.service});

  @override
  State<SystemNtpScreen> createState() => _SystemNtpScreenState();
}

class _SystemNtpScreenState extends State<SystemNtpScreen> {
  bool loading = true;
  bool enabled = false;
  String mode = 'unicast';
  final servers = TextEditingController();
  Map<String, String> state = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      state = await widget.service.ntpClient();
      enabled = state['enabled'] == 'true' || state['enabled'] == 'yes';
      mode = state['mode'] ?? 'unicast';
      servers.text = state['servers'] ?? '';
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    await widget.service.setNtpClient(
      enabled: enabled,
      mode: mode,
      servers: servers.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration NTP enregistrée.')),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('NTP / heure réseau')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Client NTP activé'),
                value: enabled,
                onChanged: (v) => setState(() => enabled = v),
              ),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Mode NTP'),
                items: const ['unicast', 'broadcast', 'manycast', 'multicast']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => mode = v ?? 'unicast'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: servers,
                decoration: const InputDecoration(
                  labelText: 'Serveurs',
                  hintText: 'pool.ntp.org',
                ),
              ),
              const SizedBox(height: 10),
              if ((state['status'] ?? '').isNotEmpty)
                Text('Statut : ${state['status']}'),
              if ((state['last-update-from'] ?? '').isNotEmpty)
                Text('Dernière source : ${state['last-update-from']}'),
              const SizedBox(height: 16),
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
    servers.dispose();
    super.dispose();
  }
}
