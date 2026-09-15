import 'package:flutter/material.dart';
import 'firewall_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class FirewallAddressListScreen extends StatefulWidget {
  final RouterOsService service;
  const FirewallAddressListScreen({super.key, required this.service});

  @override
  State<FirewallAddressListScreen> createState() =>
      _FirewallAddressListScreenState();
}

class _FirewallAddressListScreenState extends State<FirewallAddressListScreen> {
  final search = TextEditingController();
  String filter = 'all';
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.firewallAddressLists();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) {
      final dynamic = r['dynamic'] == 'true' || r['dynamic'] == 'yes';
      if (filter == 'static' && dynamic) return false;
      if (filter == 'dynamic' && !dynamic) return false;
      if (q.isNotEmpty && !r.values.any((v) => v.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> editor([Map<String, String>? row]) async {
    final list = TextEditingController(text: row?['list'] ?? '');
    final address = TextEditingController(text: row?['address'] ?? '');
    final timeout = TextEditingController(text: row?['timeout'] ?? '');
    final comment = TextEditingController(text: row?['comment'] ?? '');

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              row == null ? 'Ajouter une adresse' : 'Modifier l’adresse',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: list,
                    decoration: const InputDecoration(labelText: 'Liste'),
                  ),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Adresse'),
                  ),
                  TextField(
                    controller: timeout,
                    decoration: const InputDecoration(
                      labelText: 'Timeout',
                      hintText: '1h, 1d ou vide',
                    ),
                  ),
                  TextField(
                    controller: comment,
                    decoration: const InputDecoration(labelText: 'Commentaire'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    final error =
        FirewallInputValidator.addressListName(list.text) ??
        FirewallInputValidator.ipv4RangeOrCidrOrEmpty(
          address.text,
          label: 'Adresse',
        ) ??
        FirewallInputValidator.timeout(timeout.text);
    if (error != null || address.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Adresse obligatoire.')),
        );
      }
      return;
    }

    final values = <String, String>{
      'list': list.text.trim(),
      'address': address.text.trim(),
      if (timeout.text.trim().isNotEmpty) 'timeout': timeout.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    if (row == null) {
      await widget.service.add('/ip/firewall/address-list', values);
    } else {
      await widget.service.set(
        '/ip/firewall/address-list',
        row['.id']!,
        values,
      );
    }
    await load();
  }

  Future<void> delete(Map<String, String> row) async {
    final id = row['.id'];
    final dynamic = row['dynamic'] == 'true' || row['dynamic'] == 'yes';
    if (id == null || dynamic) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer de l’Address List ?'),
            content: Text(
              '${row['list'] ?? '—'} • ${row['address'] ?? '—'}\n\n'
              'Cette adresse peut être référencée par plusieurs règles firewall.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await widget.service.remove('/ip/firewall/address-list', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Address Lists'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Liste, adresse ou commentaire',
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('Toutes')),
              ButtonSegment(value: 'static', label: Text('Statiques')),
              ButtonSegment(value: 'dynamic', label: Text('Dynamiques')),
            ],
            selected: {filter},
            onSelectionChanged: (v) => setState(() => filter = v.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => editor(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final r = visible[i];
                      final dynamic =
                          r['dynamic'] == 'true' || r['dynamic'] == 'yes';
                      return Card(
                        child: ListTile(
                          leading: Icon(dynamic ? Icons.bolt : Icons.list_alt),
                          title: Text(
                            '${r['list'] ?? '—'} • ${r['address'] ?? '—'}',
                          ),
                          subtitle: Text(
                            [
                              if ((r['timeout'] ?? '').isNotEmpty)
                                'Timeout ${r['timeout']}',
                              if ((r['comment'] ?? '').isNotEmpty)
                                r['comment']!,
                            ].join(' • '),
                          ),
                          trailing: dynamic
                              ? const Text('Dynamic')
                              : PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') editor(r);
                                    if (v == 'delete') delete(r);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Modifier'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Supprimer'),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
