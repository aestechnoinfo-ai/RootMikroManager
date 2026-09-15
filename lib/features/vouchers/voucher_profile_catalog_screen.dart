import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_profile_metadata.dart';

class VoucherProfileCatalogScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherProfileCatalogScreen({super.key, required this.service});
  @override
  State<VoucherProfileCatalogScreen> createState() => _S();
}

class _S extends State<VoucherProfileCatalogScreen> {
  bool loading = true;
  String currency = '';
  List<Map<String, String>> profiles = [];
  List<Map<String, String>> users = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Future.wait([
      widget.service.hotspotProfiles(),
      widget.service.hotspotUsers(),
      AppCurrencySettings.load(),
    ]);
    profiles = r[0] as List<Map<String, String>>;
    users = r[1] as List<Map<String, String>>;
    currency = r[2] as String;
    if (mounted) setState(() => loading = false);
  }

  int used(String n) => users.where((u) => u['profile'] == n).length;
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Profils Hotspot'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Cette vue affiche uniquement /ip/hotspot/user/profile. Un profil définit les règles communes ; ce n’est jamais un ticket/voucher.',
                  ),
                ),
              ),
              for (final p in profiles)
                Builder(
                  builder: (context) {
                    final m = RootMikroManagerProfileMetadata.fromProfile(p);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.tune_outlined),
                        title: Text(p['name'] ?? '—'),
                        subtitle: Text(
                          [
                            'Tickets liés ${used(p['name'] ?? '')}',
                            if ((p['rate-limit'] ?? '').isNotEmpty)
                              'Débit ${p['rate-limit']}',
                            if ((p['shared-users'] ?? '').isNotEmpty)
                              'Partage ${p['shared-users']}',
                            if (m.validity.isNotEmpty) 'Validité ${m.validity}',
                            if (m.sellingPrice != '0')
                              'Vente ${AppCurrencySettings.formatRaw(m.sellingPrice, currency)}',
                          ].join(' • '),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
  );
}
