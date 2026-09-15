import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'wifi_config_backend.dart';
import 'wifi_wireless_safety_analyzer.dart';
import 'wifi_wireless_validator.dart';

class WifiAccessRuleEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final WifiConfigBackend backend;
  final Map<String, String>? row;
  const WifiAccessRuleEditorScreen({
    super.key,
    required this.service,
    required this.backend,
    this.row,
  });
  @override
  State<WifiAccessRuleEditorScreen> createState() => _S();
}

class _S extends State<WifiAccessRuleEditorScreen> {
  late final TextEditingController mac, signal, ssid, vlan, comment;
  String iface = '', action = 'accept';
  bool enabled = true, saving = false, loading = true;
  List<String> interfaces = [];
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    mac = TextEditingController(text: r?['mac-address'] ?? '');
    signal = TextEditingController(text: r?['signal-range'] ?? '-120..120');
    ssid = TextEditingController(text: r?['ssid-regexp'] ?? '');
    vlan = TextEditingController(text: r?['vlan-id'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    iface = r?['interface'] ?? '';
    action = widget.backend == WifiConfigBackend.modern
        ? (r?['action'] ?? 'accept')
        : ((r?['authentication'] == 'no') ? 'reject' : 'accept');
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
    load();
  }

  Future<void> load() async {
    interfaces = (await widget.service.wifiInterfacesFor(
      widget.backend.name,
    )).map((e) => e['name'] ?? '').where((e) => e.isNotEmpty).toList();
    if (iface.isNotEmpty && !interfaces.contains(iface)) interfaces.add(iface);
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final error =
        WifiWirelessValidator.macOrEmpty(mac.text) ??
        WifiWirelessValidator.vlanOrEmpty(vlan.text) ??
        WifiWirelessValidator.signalRangeOrEmpty(signal.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final issues = WifiWirelessSafetyAnalyzer.accessRule(
      action: action,
      mac: mac.text,
      interfaceName: iface,
      ssidRegexp: ssid.text,
      signalRange: signal.text,
    );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification Access List'),
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
    if (saving) return;
    setState(() => saving = true);
    final v = <String, String>{
      if (mac.text.trim().isNotEmpty) 'mac-address': mac.text.trim(),
      if (iface.isNotEmpty) 'interface': iface,
      if (signal.text.trim().isNotEmpty) 'signal-range': signal.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
      'disabled': enabled ? 'no' : 'yes',
    };
    if (widget.backend == WifiConfigBackend.modern) {
      v['action'] = action;
      if (ssid.text.trim().isNotEmpty) v['ssid-regexp'] = ssid.text.trim();
      if (vlan.text.trim().isNotEmpty) v['vlan-id'] = vlan.text.trim();
    } else {
      v['authentication'] = action == 'reject' ? 'no' : 'yes';
      v['forwarding'] = action == 'reject' ? 'no' : 'yes';
    }
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add(widget.backend.accessListPath, v);
      else
        await widget.service.set(widget.backend.accessListPath, id, v);
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
        widget.row == null ? 'Ajouter règle WiFi' : 'Modifier règle WiFi',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.backend.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mac,
                decoration: const InputDecoration(labelText: 'MAC Address'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: iface.isEmpty ? null : iface,
                decoration: const InputDecoration(labelText: 'Interface'),
                items: interfaces
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (x) => setState(() => iface = x ?? ''),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: signal,
                decoration: const InputDecoration(labelText: 'Signal Range'),
              ),
              if (widget.backend == WifiConfigBackend.modern) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: ssid,
                  decoration: const InputDecoration(labelText: 'SSID Regexp'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: vlan,
                  decoration: const InputDecoration(labelText: 'VLAN ID'),
                ),
              ],
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: action,
                decoration: const InputDecoration(labelText: 'Action'),
                items:
                    (widget.backend == WifiConfigBackend.modern
                            ? const ['accept', 'reject', 'query-radius']
                            : const ['accept', 'reject'])
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (x) => setState(() => action = x ?? 'accept'),
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
                onChanged: (x) => setState(() => enabled = x),
              ),
              if (action == 'reject')
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Les règles sont ordonnées. Un rejet trop général placé trop haut peut bloquer des clients légitimes.',
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
    mac.dispose();
    signal.dispose();
    ssid.dispose();
    vlan.dispose();
    comment.dispose();
    super.dispose();
  }
}
