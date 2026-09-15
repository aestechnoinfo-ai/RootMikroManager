import 'package:flutter/material.dart';
import 'network_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class DnsAdlistScreen extends StatefulWidget {
  final RouterOsService service;
  const DnsAdlistScreen({super.key, required this.service});

  @override
  State<DnsAdlistScreen> createState() => _DnsAdlistScreenState();
}

class _DnsAdlistScreenState extends State<DnsAdlistScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      rows = await widget.service.dnsAdlists();
    } catch (_) {
      rows = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> add() async {
    final url = TextEditingController();
    bool sslVerify = true;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (context, local) => AlertDialog(
              title: const Text('Ajouter DNS Adlist'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: url,
                    decoration: const InputDecoration(labelText: 'URL'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vérifier SSL'),
                    value: sslVerify,
                    onChanged: (v) => local(() => sslVerify = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (ok) {
      final error = NetworkInputValidator.httpUrl(
        url.text,
        label: 'URL Adlist',
      );
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      } else {
        await widget.service.add('/ip/dns/adlist', {
          'url': url.text.trim(),
          'ssl-verify': sslVerify ? 'yes' : 'no',
        });
        await load();
      }
    }
    url.dispose();
  }

  Future<void> action(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    if (action == 'enable') {
      await widget.service.enable('/ip/dns/adlist', id);
    } else if (action == 'disable') {
      await widget.service.disable('/ip/dns/adlist', id);
    } else if (action == 'delete') {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer la DNS Adlist ?'),
              content: Text(
                'La liste « ${row['url'] ?? row['file'] ?? id} » '
                'ne sera plus utilisée pour le filtrage DNS.',
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
      await widget.service.remove('/ip/dns/adlist', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('DNS Adlist'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: add,
              icon: const Icon(Icons.add_link),
              label: const Text('Ajouter une liste'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune Adlist ou fonction indisponible sur ce RouterOS.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      final disabled =
                          r['disabled'] == 'yes' || r['disabled'] == 'true';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.block_outlined),
                          title: Text(r['url'] ?? r['file'] ?? 'Adlist'),
                          subtitle: Text(
                            [
                              if ((r['name-count'] ?? '').isNotEmpty)
                                '${r['name-count']} domaines',
                              if ((r['match-count'] ?? '').isNotEmpty)
                                '${r['match-count']} correspondances',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => action(v, r),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: disabled ? 'enable' : 'disable',
                                child: Text(
                                  disabled ? 'Activer' : 'Désactiver',
                                ),
                              ),
                              const PopupMenuItem(
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
}
