import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class ZeroTierScreen extends StatefulWidget {
  final RouterOsService service;
  const ZeroTierScreen({super.key, required this.service});

  @override
  State<ZeroTierScreen> createState() => _ZeroTierScreenState();
}

class _ZeroTierScreenState extends State<ZeroTierScreen> {
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
      rows = await widget.service.zeroTierInterfaces();
    } catch (_) {
      rows = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> add() async {
    final network = TextEditingController();
    final name = TextEditingController(text: 'zt1');
    bool allowManaged = true;
    bool allowGlobal = false;
    bool allowDefault = false;

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (context, local) => AlertDialog(
              title: const Text('Ajouter réseau ZeroTier'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: network,
                      decoration: const InputDecoration(
                        labelText: 'Network ID',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow Managed'),
                      value: allowManaged,
                      onChanged: (v) => local(() => allowManaged = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow Global'),
                      value: allowGlobal,
                      onChanged: (v) => local(() => allowGlobal = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow Default'),
                      value: allowDefault,
                      onChanged: (v) => local(() => allowDefault = v),
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
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (ok && network.text.trim().isNotEmpty) {
      await widget.service.add('/zerotier/interface', {
        'name': name.text.trim().isEmpty ? 'zt1' : name.text.trim(),
        'network': network.text.trim(),
        'allow-managed': allowManaged ? 'yes' : 'no',
        'allow-global': allowGlobal ? 'yes' : 'no',
        'allow-default': allowDefault ? 'yes' : 'no',
      });
      await load();
    }

    network.dispose();
    name.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('ZeroTier'),
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
              icon: const Icon(Icons.add),
              label: const Text('Ajouter réseau ZeroTier'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
              ? const Center(
                  child: Text(
                    'ZeroTier indisponible ou aucun réseau configuré.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    return Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.hub_outlined),
                        title: Text(r['name'] ?? 'ZeroTier'),
                        subtitle: Text(
                          [
                            if ((r['network'] ?? '').isNotEmpty)
                              'Network ${r['network']}',
                            if ((r['status'] ?? '').isNotEmpty) r['status']!,
                          ].join(' • '),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              r.entries
                                  .where(
                                    (e) => !e.key.toLowerCase().contains(
                                      'identity',
                                    ),
                                  )
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join('\n'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
