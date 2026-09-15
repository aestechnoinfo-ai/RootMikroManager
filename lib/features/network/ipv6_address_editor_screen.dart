import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class Ipv6AddressEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const Ipv6AddressEditorScreen({super.key, required this.service, this.row});
  @override
  State<Ipv6AddressEditorScreen> createState() => _State();
}

class _State extends State<Ipv6AddressEditorScreen> {
  late final TextEditingController address, comment;
  String interface = '';
  bool advertise = false,
      eui64 = false,
      enabled = true,
      loading = true,
      saving = false;
  List<String> interfaces = [];
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    address = TextEditingController(text: r?['address'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    interface = r?['interface'] ?? '';
    advertise = r?['advertise'] == 'yes';
    eui64 = r?['eui-64'] == 'yes';
    enabled = r?['disabled'] != 'yes';
    load();
  }

  Future<void> load() async {
    interfaces =
        (await widget.service.interfaces())
            .map((e) => e['name'] ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    if (interface.isNotEmpty && !interfaces.contains(interface))
      interfaces.add(interface);
    if (mounted) setState(() => loading = false);
  }

  bool validAddress(String v) {
    final p = v.trim().split('/');
    if (p.length != 2 || !p[0].contains(':')) return false;
    final n = int.tryParse(p[1]);
    return n != null && n >= 0 && n <= 128;
  }

  Future<void> save() async {
    if (!validAddress(address.text) || interface.isEmpty || saving) {
      if (!validAddress(address.text))
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adresse IPv6/prefixe invalide.')),
        );
      return;
    }
    if (advertise && !address.text.trim().endsWith('/64')) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Préfixe non /64'),
              content: const Text(
                'SLAAC utilise normalement un préfixe /64. Continuer avec advertise=yes ?',
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
      'address': address.text.trim(),
      'interface': interface,
      'advertise': advertise ? 'yes' : 'no',
      'eui-64': eui64 ? 'yes' : 'no',
      'disabled': enabled ? 'no' : 'yes',
      'comment': comment.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/ipv6/address', v);
      else
        await widget.service.set('/ipv6/address', id, v);
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
            ? 'Ajouter une adresse IPv6'
            : 'Modifier l’adresse IPv6',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: address,
                decoration: const InputDecoration(
                  labelText: 'Adresse / préfixe',
                  hintText: '2001:db8::1/64',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: interface.isEmpty ? null : interface,
                decoration: const InputDecoration(labelText: 'Interface'),
                items: interfaces
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => interface = v ?? ''),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Advertise'),
                subtitle: const Text(
                  'Annonce automatiquement le préfixe via Neighbor Discovery.',
                ),
                value: advertise,
                onChanged: (v) => setState(() => advertise = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('EUI-64'),
                subtitle: const Text(
                  'Construit l’identifiant d’interface à partir de la MAC.',
                ),
                value: eui64,
                onChanged: (v) => setState(() => eui64 = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activée'),
                value: enabled,
                onChanged: (v) => setState(() => enabled = v),
              ),
              TextField(
                controller: comment,
                decoration: const InputDecoration(labelText: 'Commentaire'),
              ),
              if (advertise)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Avec advertise=yes, RouterOS ajoute automatiquement une entrée de préfixe ND dynamique pour ce réseau.',
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
    address.dispose();
    comment.dispose();
    super.dispose();
  }
}
