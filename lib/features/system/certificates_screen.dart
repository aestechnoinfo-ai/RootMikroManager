import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class CertificatesScreen extends StatefulWidget {
  final RouterOsService service;
  const CertificatesScreen({super.key, required this.service});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final search = TextEditingController();
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
    rows = await widget.service.certificates();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> setTrusted(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final trusted = row['trusted'] == 'yes' || row['trusted'] == 'true';
    await widget.service.set('/certificate', id, {
      'trusted': trusted ? 'no' : 'yes',
    });
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Certificats'),
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
              labelText: 'Nom, CN, fingerprint…',
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
                      final trusted =
                          r['trusted'] == 'yes' || r['trusted'] == 'true';
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            trusted
                                ? Icons.verified_user_outlined
                                : Icons.shield_outlined,
                          ),
                          title: Text(
                            r['name'] ?? r['common-name'] ?? 'Certificat',
                          ),
                          subtitle: Text(
                            [
                              if ((r['common-name'] ?? '').isNotEmpty)
                                'CN ${r['common-name']}',
                              if ((r['expires-after'] ?? '').isNotEmpty)
                                'Expire ${r['expires-after']}',
                              if ((r['fingerprint'] ?? '').isNotEmpty)
                                'FP ${r['fingerprint']}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'trust') setTrusted(r);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'trust',
                                child: Text(
                                  trusted
                                      ? 'Retirer confiance'
                                      : 'Faire confiance',
                                ),
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
