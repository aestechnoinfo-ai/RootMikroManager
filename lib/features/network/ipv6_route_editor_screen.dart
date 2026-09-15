import 'package:flutter/material.dart';
import 'routing_policy_analyzer.dart';
import 'network_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class Ipv6RouteEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const Ipv6RouteEditorScreen({super.key, required this.service, this.row});
  @override
  State<Ipv6RouteEditorScreen> createState() => _State();
}

class _State extends State<Ipv6RouteEditorScreen> {
  late final TextEditingController dst, gateway, distance, comment;
  String table = 'main';
  bool enabled = true, loading = true, saving = false;
  List<String> tables = ['main'];
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    dst = TextEditingController(text: r?['dst-address'] ?? '::/0');
    gateway = TextEditingController(text: r?['gateway'] ?? '');
    distance = TextEditingController(text: r?['distance'] ?? '1');
    comment = TextEditingController(text: r?['comment'] ?? '');
    table = r?['routing-table'] ?? 'main';
    enabled = r?['disabled'] != 'yes';
    load();
  }

  Future<void> load() async {
    tables = (await widget.service.routingTablesAdvanced())
        .map((e) => e['name'] ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    if (!tables.contains('main')) tables.insert(0, 'main');
    if (!tables.contains(table)) tables.add(table);
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving) return;
    final d = int.tryParse(distance.text.trim());
    final error =
        NetworkInputValidator.ipv6Cidr(dst.text) ??
        NetworkInputValidator.ipv6Gateway(gateway.text) ??
        NetworkInputValidator.integerRange(
          distance.text,
          label: 'Distance',
          min: 1,
          max: 255,
        );
    if (error != null || d == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Distance invalide.')));
      return;
    }
    if (dst.text.trim() == '::/0') {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Route IPv6 par défaut'),
              content: Text(
                'Créer/modifier ::/0 dans la table $table peut changer l’accès Internet ou le chemin de management.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
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
    final v = {
      'dst-address': dst.text.trim(),
      'gateway': gateway.text.trim(),
      'distance': '$d',
      'routing-table': table,
      'disabled': enabled ? 'no' : 'yes',
      'comment': comment.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/ipv6/route', v);
      else
        await widget.service.set('/ipv6/route', id, v);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null
            ? 'Ajouter une route IPv6'
            : 'Modifier la route IPv6',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: dst,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  hintText: '2001:db8:2::/64 ou ::/0',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gateway,
                decoration: const InputDecoration(
                  labelText: 'Gateway',
                  hintText: 'fe80::1%ether1 ou 2001:db8::1',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: table,
                decoration: const InputDecoration(labelText: 'Routing Table'),
                items: tables
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => table = v ?? 'main'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: distance,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Distance (1–255)',
                ),
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
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Pour une gateway link-local fe80::/10, précisez normalement l’interface, par exemple fe80::1%ether1.',
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
    dst.dispose();
    gateway.dispose();
    distance.dispose();
    comment.dispose();
    super.dispose();
  }
}
