import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'ppp_active_screen.dart';
import 'ppp_export_screen.dart';
import 'ppp_interfaces_screen.dart';
import 'ppp_safety_audit_screen.dart';
import 'ppp_secret_health_screen.dart';
import 'ppp_profile_usage_screen.dart';
import 'ppp_unused_profile_screen.dart';
import 'ppp_orphan_session_screen.dart';
import 'ppp_management_screen.dart';
import 'pppoe_server_screen.dart';
import 'ppp_secret_consistency_screen.dart';
import 'ppp_export_readiness_screen.dart';
import 'ppp_secret_safety_summary_screen.dart';
import 'ppp_software_readiness_screen.dart';
import 'ppp_destructive_action_audit_screen.dart';
import 'ppp_profile_consistency_screen.dart';

class PppHubScreen extends StatelessWidget {
  final RouterOsService service;
  const PppHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PPP / PPPoE')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _button(
          context,
          'Secrets & profils',
          'Comptes PPP et profils de connexion',
          Icons.manage_accounts_outlined,
          AppRoutes.hubPppManagement,
        ),
        _button(
          context,
          'Sessions actives',
          'Monitoring, recherche et déconnexion',
          Icons.online_prediction_outlined,
          AppRoutes.hubPppActive,
        ),
        _button(
          context,
          'Serveurs PPPoE',
          'État et activation des services PPPoE',
          Icons.router_outlined,
          AppRoutes.hubPppoeServer,
        ),
        _button(
          context,
          'Interfaces PPP',
          'PPPoE, L2TP, SSTP, OVPN et PPTP dynamiques',
          Icons.lan_outlined,
          AppRoutes.hubPppInterfaces,
        ),
        _button(
          context,
          'Exporter PPP',
          'Exporter les secrets en CSV',
          Icons.file_download_outlined,
          AppRoutes.hubPppExport,
        ),
        _button(
          context,
          'Audit PPP',
          'Doublons, profils, pools et sessions incohérentes',
          Icons.fact_check_outlined,
          AppRoutes.hubPppSafetyAudit,
        ),
        _button(
          context,
          'Utilisation des profils',
          'Secrets et sessions actives par profil PPP',
          Icons.account_tree_outlined,
          AppRoutes.hubPppProfileUsage,
        ),
        _button(
          context,
          'Santé des comptes',
          'Mots de passe absents, doublons et services permissifs',
          Icons.health_and_safety_outlined,
          AppRoutes.hubPppSecretHealth,
        ),
        _button(
          context,
          'Sessions orphelines',
          'Sessions actives sans secret PPP correspondant',
          Icons.link_off_outlined,
          AppRoutes.hubPppOrphanSession,
        ),
        _button(
          context,
          'Profils inutilisés',
          'Profils sans secret ni session active',
          Icons.layers_clear_outlined,
          AppRoutes.hubPppUnusedProfile,
        ),
        _button(
          context,
          'Cohérence profils PPP',
          'Profils référencés et pools local/remote',
          Icons.rule_outlined,
          AppRoutes.hubPppProfileConsistency,
        ),
        _button(
          context,
          'Cohérence secrets PPP',
          'Noms, services et profils sans exposer les mots de passe',
          Icons.verified_user_outlined,
          AppRoutes.hubPppSecretConsistency,
        ),
        _button(
          context,
          'Synthèse sécurité PPP',
          'Doublons, profils absents et sessions actives',
          Icons.health_and_safety_outlined,
          AppRoutes.hubPppSecretSafetySummary,
        ),
        _button(
          context,
          'Pré-gel logiciel PPP',
          'État logiciel avant tests RouterOS réels',
          Icons.task_alt_outlined,
          AppRoutes.hubPppSoftwareReadiness,
        ),
        _button(
          context,
          'Sécurité suppressions PPP',
          'Vérifier sessions actives et dépendances avant suppression',
          Icons.admin_panel_settings_outlined,
          AppRoutes.hubPppDestructiveActionAudit,
        ),
      ],
    ),
  );

  Widget _button(
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
            children: [
              Text(title),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}
