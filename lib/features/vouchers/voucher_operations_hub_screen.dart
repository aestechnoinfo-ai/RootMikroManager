import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'voucher_profile_catalog_screen.dart';
import 'voucher_ticket_catalog_screen.dart';
import 'voucher_profile_usage_screen.dart';
import 'voucher_duplicate_audit_screen.dart';
import 'voucher_batch_cleanup_screen.dart';
import 'voucher_safety_summary_screen.dart';
import 'voucher_batch_preview_screen.dart';
import 'hotspot_stale_cookie_cleanup_screen.dart';
import 'voucher_print_readiness_screen.dart';
import 'voucher_history_integrity_screen.dart';
import 'voucher_reprint_selection_screen.dart';
import 'hotspot_expiration_integrity_screen.dart';
import 'voucher_reprint_filter_screen.dart';
import 'hotspot_lifecycle_summary_screen.dart';
import 'voucher_sales_reconciliation_screen.dart';
import 'hotspot_profile_monitor_audit_screen.dart';
import 'hotspot_expiration_repair_screen.dart';
import 'voucher_status_check_screen.dart';
import 'voucher_semantics_audit_screen.dart';
import 'voucher_lifecycle_consistency_screen.dart';
import 'voucher_software_readiness_screen.dart';
import 'voucher_portal_readiness_screen.dart';
import '../hotspot/hotspot_profile_safety_screen.dart';

class VoucherOperationsHubScreen extends StatelessWidget {
  final RouterOsService service;
  const VoucherOperationsHubScreen({super.key, required this.service});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Gestion avancée des vouchers')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'RootMikroManager sépare strictement les profils Hotspot (/ip/hotspot/user/profile) des tickets/vouchers (/ip/hotspot/user).',
            ),
          ),
        ),
        b(
          c,
          'Profils Hotspot',
          'Règles communes : débit, shared-users, validité et prix',
          Icons.tune_outlined,
          AppRoutes.hubVoucherProfileCatalog,
        ),
        b(
          c,
          'Sécurité profils Hotspot',
          'Validité, doublons, schedulers et dépendances',
          Icons.verified_outlined,
          AppRoutes.hubHotspotProfileSafety,
        ),
        b(
          c,
          'Tickets / Vouchers',
          'Utilisateurs réellement générés',
          Icons.confirmation_number_outlined,
          AppRoutes.hubVoucherTicketCatalog,
        ),
        b(
          c,
          'État d’un voucher',
          'Routeur, actif, cookie, scheduler, historique et vente',
          Icons.manage_search_outlined,
          AppRoutes.hubVoucherStatusCheck,
        ),
        b(
          c,
          'Portail captif & QR',
          'Valider l’URL utilisée pour les QR des tickets',
          Icons.qr_code_scanner_outlined,
          AppRoutes.hubVoucherPortalReadiness,
        ),
        b(
          c,
          'Sémantique vouchers & ventes',
          'Séparer génération, vente et réimpression',
          Icons.account_tree_outlined,
          AppRoutes.hubVoucherSemanticsAudit,
        ),
        b(
          c,
          'Utilisation des profils',
          'Compter les tickets et actifs par profil',
          Icons.account_tree_outlined,
          AppRoutes.hubVoucherProfileUsage,
        ),
        b(
          c,
          'Audit doublons',
          'Détecter les usernames dupliqués',
          Icons.copy_all_outlined,
          AppRoutes.hubVoucherDuplicateAudit,
        ),
        b(
          c,
          'Suppression de tickets',
          'Individuel, sélection, profil ou commentaire de lot Mikhmon',
          Icons.preview_outlined,
          AppRoutes.hubVoucherBatchPreview,
        ),
        b(
          c,
          'Nettoyage d’un lot',
          'Suppression rapide des tickets inutilisés d’un lot',
          Icons.delete_sweep_outlined,
          AppRoutes.hubVoucherBatchCleanup,
        ),
        b(
          c,
          'Cookies orphelins',
          'Nettoyer les cookies de tickets supprimés/expirés',
          Icons.cookie_outlined,
          AppRoutes.hubHotspotStaleCookieCleanup,
        ),
        b(
          c,
          'Audit expiration',
          'Validité, schedulers, cookies et sessions des tickets expirés',
          Icons.timer_off_outlined,
          AppRoutes.hubHotspotExpirationIntegrity,
        ),
        b(
          c,
          'Réparer expirations',
          'Nettoyage sélectif cookie, actif, scheduler puis ticket',
          Icons.cleaning_services_outlined,
          AppRoutes.hubHotspotExpirationRepair,
        ),
        b(
          c,
          'Moniteurs de validité',
          'Auditer et réparer les schedulers des profils expirables',
          Icons.schedule_outlined,
          AppRoutes.hubHotspotProfileMonitorAudit,
        ),
        b(
          c,
          'Audit impression',
          'Format papier, QR, densité et devise',
          Icons.print_outlined,
          AppRoutes.hubVoucherPrintReadiness,
        ),
        b(
          c,
          'Audit historique',
          'Doublons, profils, prix et devise des vouchers archivés',
          Icons.history_outlined,
          AppRoutes.hubVoucherHistoryIntegrity,
        ),
        b(
          c,
          'Réimpression filtrée',
          'Rechercher, filtrer par profil et réimprimer en lot',
          Icons.print_outlined,
          AppRoutes.hubVoucherReprintFilter,
        ),
        b(
          c,
          'Rapprochement ventes',
          'Comparer historique local et ventes RouterOS',
          Icons.compare_arrows_outlined,
          AppRoutes.hubVoucherSalesReconciliation,
        ),
        b(
          c,
          'Cycle de vie Hotspot',
          'Vue synthèse tickets, actifs, cookies et expirés',
          Icons.autorenew_outlined,
          AppRoutes.hubHotspotLifecycleSummary,
        ),
        b(
          c,
          'Pré-gel logiciel vouchers',
          'État logiciel avant tests réels',
          Icons.task_alt_outlined,
          AppRoutes.hubVoucherSoftwareReadiness,
        ),
        b(
          c,
          'Cohérence cycle de vie',
          'Tickets, sessions, cookies et orphelins',
          Icons.sync_problem_outlined,
          AppRoutes.hubVoucherLifecycleConsistency,
        ),
        b(
          c,
          'Sécurité',
          'Profils absents, cookies et sessions orphelins',
          Icons.health_and_safety_outlined,
          AppRoutes.hubVoucherSafetySummary,
        ),
      ],
    ),
  );
  Widget b(BuildContext c, String t, String s, IconData i, String routeName) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FilledButton.tonalIcon(
          onPressed: () => AppRouter.pushNamed(c, routeName),
          icon: Icon(i),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t),
                  Text(s, style: Theme.of(c).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );
}
