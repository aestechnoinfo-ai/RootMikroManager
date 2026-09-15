import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class ReportExportHubScreen extends StatelessWidget {
  final RouterOsService service;
  const ReportExportHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Exports & impression')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        button(
          context,
          'Selling Report',
          'Rapport des ventes, impression et export',
          Icons.payments_outlined,
          AppRoutes.reportSales,
        ),
        button(
          context,
          'User Log',
          'Connexions utilisateurs, PDF et CSV',
          Icons.manage_accounts_outlined,
          AppRoutes.reportUserLog,
        ),
        button(
          context,
          'Resume mensuel',
          'Revenus quotidiens avec devise, PDF et CSV',
          Icons.bar_chart_outlined,
          AppRoutes.reportMonthly,
        ),
        button(
          context,
          'Période exacte',
          'Exporter les ventes entre deux dates',
          Icons.date_range_outlined,
          AppRoutes.reportSalesDateRange,
        ),
        button(
          context,
          'Historique vouchers',
          'Réimpression et export de l’historique local',
          Icons.history_outlined,
          AppRoutes.voucherHistory,
        ),
      ],
    ),
  );

  Widget button(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String routeName,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton.tonalIcon(
      onPressed: () => AppRouter.pushNamed(context, routeName),
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(title), Text(subtitle)],
          ),
        ),
      ),
    ),
  );
}
