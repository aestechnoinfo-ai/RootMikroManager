import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class ReportsScreen extends StatefulWidget {
  final RouterOsService service;
  const ReportsScreen({super.key, required this.service});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool loading = true;
  String? error;
  List<int> counts = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final values = await Future.wait([
        widget.service.hotspotUsers(),
        widget.service.activeUsers(),
        widget.service.pppSecrets(),
        widget.service.pppActive(),
        widget.service.dhcpLeases(),
        widget.service.simpleQueues(),
        widget.service.rootmikromanagerSalesScripts(),
      ]);
      counts = values.map((e) => e.length).toList();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Rapports'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _action(
                  'Live Report',
                  'CA et vouchers : jour, semaine, mois et total',
                  Icons.monitor_heart_outlined,
                  () => AppRouter.pushNamed(context, AppRoutes.reportLive),
                ),
                const SizedBox(height: 8),
                _action(
                  'Selling Report RootMikroManager',
                  '${counts[6]} enregistrement(s) RouterOS',
                  Icons.payments_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSales,
                  ).then((_) => load()),
                ),
                const SizedBox(height: 8),
                _action(
                  'User Log RootMikroManager',
                  'Date, heure, utilisateur, IP, MAC et validité',
                  Icons.manage_accounts_outlined,
                  () => AppRouter.pushNamed(context, AppRoutes.reportUserLog),
                ),
                const SizedBox(height: 8),
                _action(
                  'Resume Report mensuel',
                  'Vouchers et revenu par jour avec devise',
                  Icons.bar_chart_outlined,
                  () => AppRouter.pushNamed(context, AppRoutes.reportMonthly),
                ),
                const SizedBox(height: 8),
                _action(
                  'Ventes par profil',
                  'Volume et chiffre d’affaires par profil avec devise',
                  Icons.stacked_bar_chart_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSalesProfile,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Audit des ventes',
                  'Prix, profils, dates et cohérence de la devise',
                  Icons.fact_check_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSalesIntegrity,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Doublons des ventes',
                  'Détecter les enregistrements strictement dupliqués',
                  Icons.copy_all_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSalesDuplicates,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Exporter une période',
                  'CSV entre deux dates exactes avec total et devise',
                  Icons.date_range_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSalesDateRange,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Registre des ventes',
                  'CA dédupliqué : une réimpression ne devient jamais une vente',
                  Icons.receipt_long_outlined,
                  () =>
                      AppRouter.pushNamed(context, AppRoutes.reportSalesLedger),
                ),
                const SizedBox(height: 8),
                _action(
                  'Cohérence des ventes',
                  'Ventes uniques, doublons, lignes invalides et CA retenu',
                  Icons.rule_folder_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSalesConsistency,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Exports & impression',
                  'Centraliser PDF, CSV et historique vouchers',
                  Icons.file_present_outlined,
                  () => AppRouter.pushNamed(context, AppRoutes.reportExportHub),
                ),
                const SizedBox(height: 8),
                _action(
                  'CA dédupliqué',
                  'Calculer le chiffre d’affaires en excluant les doublons stricts',
                  Icons.calculate_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSalesUniqueRevenue,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Audit conservation des ventes',
                  'Ancienneté, dates reconnues et montant historique',
                  Icons.inventory_2_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSalesRetention,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Qualité des données ventes',
                  'Dates, prix, profils et doublons du registre',
                  Icons.data_thresholding_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSalesDataQuality,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'État de préparation gestionnaire',
                  'Hotspot, validité, devise, QR, impression, PPP et ventes',
                  Icons.fact_check_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportManagementReadiness,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Gel logiciel gestionnaire',
                  'Synthèse du pré-gel avant les tests réels différés',
                  Icons.lock_clock_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportManagerFreeze,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Périmètre de validation',
                  'Ce qui est vérifié maintenant et ce qui sera testé plus tard',
                  Icons.rule_outlined,
                  () =>
                      AppRouter.pushNamed(context, AppRoutes.reportStaticAudit),
                ),
                const SizedBox(height: 8),
                _action(
                  'Matrice de validation gestionnaire',
                  'Séparer ce qui est validé statiquement des tests matériels',
                  Icons.checklist_rtl_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportValidationMatrix,
                  ),
                ),
                const SizedBox(height: 8),
                _action(
                  'Nettoyage des ventes',
                  'Aperçu puis suppression sûre par jour ou mois',
                  Icons.delete_sweep_outlined,
                  () => AppRouter.pushNamed(
                    context,
                    AppRoutes.reportSalesCleanup,
                  ).then((_) => load()),
                ),
                const SizedBox(height: 8),
                _action(
                  'Historique vouchers local',
                  'Historique SQLite RootMikroManager',
                  Icons.confirmation_number_outlined,
                  () => AppRouter.pushNamed(context, AppRoutes.voucherHistory),
                ),
                const SizedBox(height: 14),
                Text(
                  'État du routeur',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _stats(),
              ],
            ),
          ),
  );

  Widget _action(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) => SizedBox(
    width: double.infinity,
    child: FilledButton.tonal(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );

  Widget _stats() => LayoutBuilder(
    builder: (context, c) {
      final cols = c.maxWidth >= 900
          ? 3
          : c.maxWidth >= 520
          ? 2
          : 1;
      final width = (c.maxWidth - ((cols - 1) * 8)) / cols;
      final data = [
        ('Hotspot Users', counts[0], Icons.people_outline),
        ('Hotspot Active', counts[1], Icons.online_prediction_outlined),
        ('PPP Secrets', counts[2], Icons.key_outlined),
        ('PPP Active', counts[3], Icons.lan_outlined),
        ('DHCP Leases', counts[4], Icons.router_outlined),
        ('Simple Queues', counts[5], Icons.speed_outlined),
      ];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final d in data)
            SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(d.$3),
                      const SizedBox(width: 10),
                      Expanded(child: Text(d.$1)),
                      Text(
                        '${d.$2}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
