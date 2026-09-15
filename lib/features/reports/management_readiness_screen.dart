import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import '../vouchers/voucher_template_settings.dart';
import '../vouchers/voucher_paper_format.dart';

class ManagementReadinessScreen extends StatefulWidget {
  final RouterOsService service;
  const ManagementReadinessScreen({super.key, required this.service});

  @override
  State<ManagementReadinessScreen> createState() => _State();
}

class _State extends State<ManagementReadinessScreen> {
  bool loading = true;
  final rows = <({String title, bool ok, String detail})>[];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);

    final values = await Future.wait([
      widget.service.hotspotProfiles(),
      widget.service.hotspotUsers(),
      widget.service.hotspotServers(),
      widget.service.schedulers(),
      widget.service.pppProfiles(),
      widget.service.pppSecrets(),
      widget.service.rootmikromanagerSalesScripts(),
      AppCurrencySettings.load(),
      VoucherTemplateSettings.load(),
    ]);

    final profiles = values[0] as List<Map<String, String>>;
    final users = values[1] as List<Map<String, String>>;
    final servers = values[2] as List<Map<String, String>>;
    final schedulers = values[3] as List<Map<String, String>>;
    final pppProfiles = values[4] as List<Map<String, String>>;
    final pppSecrets = values[5] as List<Map<String, String>>;
    final sales = values[6] as List<Map<String, String>>;
    final currency = values[7] as String;
    final template = values[8] as VoucherTemplateSettings;

    final expirableProfiles = profiles.where((row) {
      final onLogin = row['on-login'] ?? '';
      return onLogin.contains(',rem,') ||
          onLogin.contains(',ntf,') ||
          onLogin.contains(',remc,') ||
          onLogin.contains(',ntfc,');
    }).toList();

    final missingMonitors = expirableProfiles.where((profile) {
      final name = profile['name'] ?? '';
      return !schedulers.any((e) => e['name'] == name);
    }).length;

    rows
      ..clear()
      ..add((
        title: 'Serveur Hotspot',
        ok: servers.isNotEmpty,
        detail: servers.isEmpty
            ? 'Aucun serveur Hotspot détecté.'
            : '${servers.length} serveur(s) détecté(s).',
      ))
      ..add((
        title: 'Profils Hotspot',
        ok: profiles.isNotEmpty,
        detail: '${profiles.length} profil(s) • ${users.length} ticket(s).',
      ))
      ..add((
        title: 'Moniteurs de validité',
        ok: missingMonitors == 0,
        detail: missingMonitors == 0
            ? 'Schedulers cohérents pour les profils expirables.'
            : '$missingMonitors profil(s) expirables sans scheduler.',
      ))
      ..add((
        title: 'Devise',
        ok: currency.trim().isNotEmpty,
        detail: currency.trim().isEmpty
            ? 'Devise non configurée.'
            : 'Devise globale : $currency.',
      ))
      ..add((
        title: 'QR / portail captif',
        ok: !template.showQr || template.loginUrl.trim().isNotEmpty,
        detail: !template.showQr
            ? 'QR désactivé.'
            : template.loginUrl.trim().isEmpty
            ? 'QR activé mais URL de connexion absente.'
            : 'URL QR configurée.',
      ))
      ..add((
        title: 'Impression',
        ok:
            template.safeTicketsPerPage >= 1 &&
            template.safeTicketsPerPage <= 50,
        detail:
            '${template.safeTicketsPerPage} ticket(s)/page • ${template.paperFormat.label}.',
      ))
      ..add((
        title: 'PPP',
        ok: pppProfiles.isNotEmpty || pppSecrets.isEmpty,
        detail:
            '${pppProfiles.length} profil(s) • ${pppSecrets.length} secret(s).',
      ))
      ..add((
        title: 'Registre des ventes',
        ok: true,
        detail: '${sales.length} enregistrement(s) RouterOS détecté(s).',
      ));

    if (mounted) setState(() => loading = false);
  }

  int get okCount => rows.where((e) => e.ok).length;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('État de préparation gestionnaire'),
      actions: [
        IconButton(
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text('$okCount/${rows.length} contrôles prêts'),
                  subtitle: const Text(
                    'Contrôle logiciel non destructif avant validation '
                    'sur un routeur et une imprimante réels.',
                  ),
                ),
              ),
              for (final row in rows)
                Card(
                  child: ListTile(
                    leading: Icon(
                      row.ok
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                    ),
                    title: Text(row.title),
                    subtitle: Text(row.detail),
                  ),
                ),
            ],
          ),
  );
}
