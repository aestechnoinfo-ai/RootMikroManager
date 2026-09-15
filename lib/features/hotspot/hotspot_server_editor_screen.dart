import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotServerEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const HotspotServerEditorScreen({super.key, required this.service, this.row});
  @override
  State<HotspotServerEditorScreen> createState() =>
      _HotspotServerEditorScreenState();
}

class _HotspotServerEditorScreenState extends State<HotspotServerEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController addressesPerMac;
  late final TextEditingController idleTimeout;
  late final TextEditingController keepaliveTimeout;
  late final TextEditingController loginTimeout;
  String interfaceName = '';
  String addressPool = 'none';
  String profile = 'default';
  bool enabled = true, saving = false, loading = true;
  List<String> interfaces = [], pools = ['none'], profiles = ['default'];

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    addressesPerMac = TextEditingController(
      text: r?['addresses-per-mac'] ?? '2',
    );
    idleTimeout = TextEditingController(text: r?['idle-timeout'] ?? '5m');
    keepaliveTimeout = TextEditingController(
      text: r?['keepalive-timeout'] ?? '2m',
    );
    loginTimeout = TextEditingController(text: r?['login-timeout'] ?? '2m');
    interfaceName = r?['interface'] ?? '';
    addressPool = r?['address-pool'] ?? 'none';
    profile = r?['profile'] ?? 'default';
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
    loadOptions();
  }

  Future<void> loadOptions() async {
    final result = await Future.wait([
      widget.service.interfaces(),
      widget.service.ipPools(),
      widget.service.hotspotServerProfiles(),
    ]);
    interfaces = result[0]
        .map((e) => e['name'] ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    pools = [
      'none',
      ...result[1].map((e) => e['name'] ?? '').where((e) => e.isNotEmpty),
    ];
    profiles = result[2]
        .map((e) => e['name'] ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    if (interfaceName.isEmpty && interfaces.isNotEmpty)
      interfaceName = interfaces.first;
    if (!pools.contains(addressPool)) pools.add(addressPool);
    if (!profiles.contains(profile)) profiles.add(profile);
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || interfaceName.isEmpty || saving) return;
    setState(() => saving = true);
    try {
      final values = <String, String>{
        'name': name.text.trim(),
        'interface': interfaceName,
        'address-pool': addressPool,
        'profile': profile,
        'addresses-per-mac': addressesPerMac.text.trim(),
        'idle-timeout': idleTimeout.text.trim(),
        'keepalive-timeout': keepaliveTimeout.text.trim(),
        'login-timeout': loginTimeout.text.trim(),
        'disabled': enabled ? 'no' : 'yes',
      };
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/ip/hotspot', values);
      else
        await widget.service.set('/ip/hotspot', id, values);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null
            ? 'Ajouter Hotspot Server'
            : 'Modifier Hotspot Server',
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
              DropdownButtonFormField<String>(
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
              DropdownButtonFormField<String>(
                value: pools.contains(addressPool) ? addressPool : 'none',
                decoration: const InputDecoration(labelText: 'Address Pool'),
                items: pools
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => addressPool = v ?? 'none'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: profiles.contains(profile) ? profile : null,
                decoration: const InputDecoration(labelText: 'Server Profile'),
                items: profiles
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => profile = v ?? profile),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressesPerMac,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Addresses per MAC',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: idleTimeout,
                decoration: const InputDecoration(labelText: 'Idle Timeout'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: keepaliveTimeout,
                decoration: const InputDecoration(
                  labelText: 'Keepalive Timeout',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: loginTimeout,
                decoration: const InputDecoration(labelText: 'Login Timeout'),
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
    addressesPerMac.dispose();
    idleTimeout.dispose();
    keepaliveTimeout.dispose();
    loginTimeout.dispose();
    super.dispose();
  }
}
