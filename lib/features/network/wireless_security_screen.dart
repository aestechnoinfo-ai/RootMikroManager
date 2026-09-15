import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class WirelessSecurityScreen extends StatefulWidget {
  final RouterOsService service;
  const WirelessSecurityScreen({super.key, required this.service});
  @override
  State<WirelessSecurityScreen> createState() => _WirelessSecurityScreenState();
}

class _WirelessSecurityScreenState extends State<WirelessSecurityScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.wirelessSecurityProfilesAll();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sécurité Wi‑Fi'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Les profils /interface/wifi/security et /interface/wireless/security-profiles appartiennent à deux piles différentes. RootMikroManager les inventorie ensemble sans les fusionner.',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      return Card(
                        child: ExpansionTile(
                          leading: const Icon(Icons.security_outlined),
                          title: Text(r['name'] ?? r['.id'] ?? 'Profil'),
                          subtitle: Text(
                            [
                              r['_backend'] ?? '',
                              if ((r['authentication-types'] ?? '').isNotEmpty)
                                r['authentication-types']!,
                              if ((r['mode'] ?? '').isNotEmpty) r['mode']!,
                            ].where((e) => e.isNotEmpty).join(' • '),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SelectableText(
                                r.entries
                                    .where(
                                      (e) =>
                                          !e.key.toLowerCase().contains(
                                            'password',
                                          ) &&
                                          !e.key.toLowerCase().contains(
                                            'passphrase',
                                          ) &&
                                          !e.key.toLowerCase().contains(
                                            'pre-shared-key',
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
              ),
            ],
          ),
  );
}
