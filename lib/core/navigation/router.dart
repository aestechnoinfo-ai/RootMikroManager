import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/routers/routers_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/audit/audit_screen.dart';
import '../../features/backup/backup_hub_screen.dart';
import '../../features/network/dhcp_hub_screen.dart';
import '../../features/network/dns_hub_screen.dart';
import '../../features/network/interfaces_hub_screen.dart';
import '../../features/firewall/firewall_advanced_hub_screen.dart';
import '../../features/queues/queues_hub_screen.dart';
import '../../features/monitoring/monitoring_hub_screen.dart';
import '../../features/network/wireless_hub_screen.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/tools/network_tools_screen.dart';
import '../../features/system/system_screens.dart';
import '../../features/system/system_hub_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/ppp/ppp_export_screen.dart';
import '../../features/ppp/ppp_active_screen.dart';
import '../../features/vouchers/voucher_operations_hub_screen.dart';
import '../../features/hotspot/hotspot_settings_screen.dart';
import '../../features/vouchers/voucher_history_screen.dart';
import '../../features/reports/sales_cleanup_preview_screen.dart';
import '../../features/reports/management_validation_matrix_screen.dart';
import '../../features/reports/management_static_audit_notes_screen.dart';
import '../../features/reports/manager_software_freeze_screen.dart';
import '../../features/reports/management_readiness_screen.dart';
import '../../features/reports/sales_data_quality_screen.dart';
import '../../features/reports/sales_retention_audit_screen.dart';
import '../../features/reports/sales_unique_revenue_screen.dart';
import '../../features/reports/report_export_hub_screen.dart';
import '../../features/reports/sales_consistency_summary_screen.dart';
import '../../features/reports/sales_ledger_screen.dart';
import '../../features/reports/sales_date_range_export_screen.dart';
import '../../features/reports/sales_duplicate_audit_screen.dart';
import '../../features/reports/sales_integrity_audit_screen.dart';
import '../../features/reports/sales_profile_summary_screen.dart';
import '../../features/reports/rootmikromanager_monthly_resume_report_screen.dart';
import '../../features/reports/rootmikromanager_user_log_report_screen.dart';
import '../../features/reports/rootmikromanager_sales_report_screen.dart';
import '../../features/reports/live_report_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/ppp/ppp_hub_screen.dart';
import '../../features/vouchers/voucher_generator_screen.dart';
import '../../features/hotspot/hotspot_management_screen.dart';
import '../../features/hotspot/hotspot_winbox_screen.dart';
import '../../features/hotspot/hotspot_users_screen.dart';
import '../../features/hotspot/hotspot_advanced_screen.dart';
import '../routeros/router_session.dart';
import 'routes.dart';
import '../../features/vpn/wireguard_peer_editor_screen.dart' as vpn_wg_peer;
import '../../features/vouchers/hotspot_ticket_detail_screen.dart';
import '../../features/vouchers/voucher_batch_lifecycle_result_screen.dart';
import '../../features/network/wifi_config_backend.dart' as hub_backend;
import '../../features/vpn/vpn_hub_screen.dart' as h124;
import '../../features/vouchers/voucher_ticket_catalog_screen.dart' as h123;
import '../../features/vouchers/voucher_status_check_screen.dart' as h122;
import '../../features/vouchers/voucher_software_readiness_screen.dart' as h121;
import '../../features/vouchers/voucher_semantics_audit_screen.dart' as h120;
import '../../features/vouchers/voucher_sales_reconciliation_screen.dart'
    as h119;
import '../../features/vouchers/voucher_safety_summary_screen.dart' as h118;
import '../../features/vouchers/voucher_reprint_filter_screen.dart' as h117;
import '../../features/vouchers/voucher_profile_usage_screen.dart' as h116;
import '../../features/vouchers/voucher_profile_catalog_screen.dart' as h115;
import '../../features/vouchers/voucher_print_readiness_screen.dart' as h114;
import '../../features/vouchers/voucher_portal_readiness_screen.dart' as h113;
import '../../features/vouchers/voucher_lifecycle_consistency_screen.dart'
    as h112;
import '../../features/vouchers/voucher_history_integrity_screen.dart' as h111;
import '../../features/vouchers/voucher_duplicate_audit_screen.dart' as h110;
import '../../features/vouchers/voucher_batch_preview_screen.dart' as h109;
import '../../features/vouchers/voucher_batch_cleanup_screen.dart' as h108;
import '../../features/vouchers/hotspot_stale_cookie_cleanup_screen.dart'
    as h107;
import '../../features/vouchers/hotspot_profile_monitor_audit_screen.dart'
    as h106;
import '../../features/vouchers/hotspot_lifecycle_summary_screen.dart' as h105;
import '../../features/vouchers/hotspot_expiration_repair_screen.dart' as h104;
import '../../features/vouchers/hotspot_expiration_integrity_screen.dart'
    as h103;
import '../../features/tools/traceroute_advanced_screen.dart' as h102;
import '../../features/tools/torch_screen.dart' as h101;
import '../../features/tools/sniffer_screen.dart' as h100;
import '../../features/tools/network_tools_summary_screen.dart' as h99;
import '../../features/tools/device_mode_tools_screen.dart' as h98;
import '../../features/tools/bandwidth_test_screen.dart' as h97;
import '../../features/tools/advanced_ping_screen.dart' as h96;
import '../../features/system/system_users_screen.dart' as h95;
import '../../features/system/system_user_groups_screen.dart' as h94;
import '../../features/system/system_storage_screen.dart' as h93;
import '../../features/system/system_security_summary_screen.dart' as h92;
import '../../features/system/system_security_hub_screen.dart' as h91;
import '../../features/system/system_packages_screen.dart' as h90;
import '../../features/system/system_overview_screen.dart' as h89;
import '../../features/system/system_ntp_screen.dart' as h88;
import '../../features/system/system_identity_screen.dart' as h87;
import '../../features/system/system_health_screen.dart' as h86;
import '../../features/system/system_clock_screen.dart' as h85;
import '../../features/system/scripts_management_screen.dart' as h84;
import '../../features/system/script_permissions_screen.dart' as h83;
import '../../features/system/script_jobs_screen.dart' as h82;
import '../../features/system/scheduler_management_screen.dart' as h81;
import '../../features/system/scheduler_linkage_screen.dart' as h80;
import '../../features/system/logs_management_screen.dart' as h79;
import '../../features/system/logging_summary_screen.dart' as h78;
import '../../features/system/logging_rules_screen.dart' as h77;
import '../../features/system/logging_hub_screen.dart' as h76;
import '../../features/system/logging_export_screen.dart' as h75;
import '../../features/system/logging_diagnostics_screen.dart' as h74;
import '../../features/system/logging_buffers_screen.dart' as h73;
import '../../features/system/logging_actions_screen.dart' as h72;
import '../../features/system/ip_services_screen.dart' as h71;
import '../../features/system/certificates_screen.dart' as h70;
import '../../features/system/automation_summary_screen.dart' as h69;
import '../../features/system/automation_hub_screen.dart' as h68;
import '../../features/queues/simple_queue_screen.dart' as h67;
import '../../features/queues/queue_type_screen.dart' as h66;
import '../../features/queues/queue_tree_screen.dart' as h65;
import '../../features/queues/queue_stats_screen.dart' as h64;
import '../../features/queues/queue_monitor_screen.dart' as h63;
import '../../features/ppp/pppoe_server_screen.dart' as h62;
import '../../features/ppp/ppp_unused_profile_screen.dart' as h61;
import '../../features/ppp/ppp_software_readiness_screen.dart' as h60;
import '../../features/ppp/ppp_secret_safety_summary_screen.dart' as h59;
import '../../features/ppp/ppp_secret_health_screen.dart' as h58;
import '../../features/ppp/ppp_secret_consistency_screen.dart' as h57;
import '../../features/ppp/ppp_safety_audit_screen.dart' as h56;
import '../../features/ppp/ppp_profile_usage_screen.dart' as h55;
import '../../features/ppp/ppp_profile_consistency_screen.dart' as h54;
import '../../features/ppp/ppp_orphan_session_screen.dart' as h53;
import '../../features/ppp/ppp_management_screen.dart' as h52;
import '../../features/ppp/ppp_interfaces_screen.dart' as h51;
import '../../features/ppp/ppp_export_screen.dart' as h50;
import '../../features/ppp/ppp_destructive_action_audit_screen.dart' as h49;
import '../../features/ppp/ppp_active_screen.dart' as h48;
import '../../features/network/zerotier_peers_screen.dart' as h47;
import '../../features/network/zerotier_interfaces_screen.dart' as h46;
import '../../features/network/wireless_summary_screen.dart' as h45;
import '../../features/network/wireless_security_screen.dart' as h44;
import '../../features/network/wireless_scan_screen.dart' as h43;
import '../../features/network/wireless_registration_screen.dart' as h42;
import '../../features/network/wireless_inventory_screen.dart' as h41;
import '../../features/network/wireguard_peers_screen.dart' as h40;
import '../../features/network/wireguard_interfaces_screen.dart' as h39;
import '../../features/network/wifi_provisioning_screen.dart' as h38;
import '../../features/network/wifi_profiles_screen.dart' as h37;
import '../../features/network/wifi_config_summary_screen.dart' as h36;
import '../../features/network/wifi_config_hub_screen.dart' as h35;
import '../../features/network/wifi_capsman_screen.dart' as h34;
import '../../features/network/wifi_acl_safety_screen.dart' as h33;
import '../../features/network/wifi_access_list_screen.dart' as h32;
import '../../features/network/vrf_screen.dart' as h31;
import '../../features/network/vpn_neighbor_candidates_screen.dart' as h30;
import '../../features/network/vpn_integration_summary_screen.dart' as h29;
import '../../features/network/vpn_capability_status_screen.dart' as h28;
import '../../features/network/vpn_advanced_hub_screen.dart' as h27;
import '../../features/network/vlan_screen.dart' as h26;
import '../../features/network/routing_tables_screen.dart' as h25;
import '../../features/network/routing_rules_screen.dart' as h24;
import '../../features/network/routing_policy_summary_screen.dart' as h23;
import '../../features/network/routing_policy_safety_screen.dart' as h22;
import '../../features/network/routing_ip_hub_screen.dart' as h21;
import '../../features/network/legacy_connect_list_screen.dart' as h20;
import '../../features/network/ipv6_routes_screen.dart' as h19;
import '../../features/network/ipv6_nd_screen.dart' as h18;
import '../../features/network/ipv6_inventory_screen.dart' as h17;
import '../../features/network/ipv6_addresses_screen.dart' as h16;
import '../../features/network/ip_addresses_screen.dart' as h15;
import '../../features/network/interfaces_management_screen.dart' as h14;
import '../../features/network/interface_lists_screen.dart' as h13;
import '../../features/network/bridge_vlan_hub_screen.dart' as h12;
import '../../features/network/bridge_management_screen.dart' as h11;
import '../../features/network/bridge_hosts_screen.dart' as h10;
import '../../features/network/back_to_home_users_screen.dart' as h9;
import '../../features/network/back_to_home_status_screen.dart' as h8;
import '../../features/monitoring/interface_monitor_screen.dart' as h7;
import '../../features/hotspot/hotspot_profile_safety_screen.dart' as h6;
import '../../features/firewall/mangle_tools_screen.dart' as h5;
import '../../features/firewall/firewall_stats_screen.dart' as h4;
import '../../features/firewall/firewall_rules_screen.dart' as h3;
import '../../features/firewall/firewall_management_screen.dart' as h2;
import '../../features/firewall/firewall_address_list_screen.dart' as h1;
import '../../features/routers/router_connection_screen.dart';
import '../../features/vouchers/voucher_template_editor_screen.dart';
import '../../features/system/logging_rule_editor_screen.dart';
import '../../features/system/log_detail_screen.dart';
import '../../features/system/logging_action_editor_screen.dart';
import '../../features/queues/simple_queue_editor_screen.dart';
import '../../features/queues/queue_type_editor_screen.dart';
import '../../features/queues/queue_tree_editor_screen.dart';
import '../../features/network/wireless_detail_screen.dart';
import '../../features/network/wireguard_peer_editor_screen.dart';
import '../../features/network/wifi_profile_editor_screen.dart';
import '../../features/network/wifi_access_rule_editor_screen.dart';
import '../../features/network/interface_detail_screen.dart';
import '../../features/firewall/raw_rule_editor_screen.dart';
import '../../features/firewall/mangle_rule_editor_screen.dart';
import '../../features/firewall/nat_rule_editor_screen.dart';
import '../../features/firewall/filter_rule_editor_screen.dart';
import '../../features/firewall/firewall_rule_editor_screen.dart';
import '../../features/vpn/back_to_home_screen.dart';
import '../../features/vpn/zerotier_screen.dart';
import '../../features/vpn/wireguard_interfaces_screen.dart';
import '../../features/vpn/vpn_summary_screen.dart';
import '../../features/network/ip_neighbors_screen.dart';
import '../../features/network/ip_addresses_screen.dart';
import '../../features/network/arp_screen.dart';
import '../../features/network/ip_routes_screen.dart';
import '../../features/network/ip_address_editor_screen.dart';
import '../../features/network/routing_summary_screen.dart';
import '../../features/network/dns_diagnostics_screen.dart';
import '../../features/network/dns_adlist_screen.dart';
import '../../features/network/dns_cache_screen.dart';
import '../../features/network/dns_static_screen.dart';
import '../../features/network/dns_settings_screen.dart';
import '../../features/network/dns_summary_screen.dart';
import '../../features/network/dhcp_leases_management_screen.dart';
import '../../features/network/dhcp_networks_screen.dart';
import '../../features/network/dhcp_servers_screen.dart';
import '../../features/network/dhcp_summary_screen.dart';
import '../../features/network/bridge_vlan_capability_screen.dart';
import '../../features/network/bridge_vlan_safety_screen.dart';
import '../../features/network/interface_lists_screen.dart';
import '../../features/network/bridge_hosts_screen.dart';
import '../../features/network/bridge_vlan_table_screen.dart';
import '../../features/network/bridge_ports_screen.dart';
import '../../features/network/zerotier_interface_editor_screen.dart';
import '../../features/network/wifi_provisioning_editor_screen.dart';
import '../../features/network/vlan_editor_screen.dart';
import '../../features/network/routing_table_editor_screen.dart';
import '../../features/network/routing_rule_editor_screen.dart';
import '../../features/network/ipv6_route_editor_screen.dart';
import '../../features/network/ipv6_address_editor_screen.dart';
import '../../features/network/dns_static_editor_screen.dart';
import '../../features/network/dhcp_server_editor_screen.dart';
import '../../features/network/dhcp_network_editor_screen.dart';
import '../../features/network/dhcp_lease_editor_screen.dart';
import '../../features/network/bridge_vlan_editor_screen.dart';
import '../../features/network/bridge_editor_screen.dart';
import '../../features/network/bridge_vlan_activation_screen.dart';
import '../../features/network/bridge_port_editor_screen.dart';
import '../../features/firewall/internet_sharing_add_screen.dart';
import '../../features/network/arp_editor_screen.dart';
import '../../features/hotspot/ip_pool_editor_screen.dart';
import '../../features/hotspot/hotspot_server_editor_screen.dart';
import '../../features/hotspot/hotspot_server_profile_editor_screen.dart';
import '../../features/hotspot/hotspot_active_screen.dart';
import '../../features/hotspot/ip_pool_screen.dart';
import '../../features/hotspot/hotspot_server_profile_screen.dart';
import '../../features/hotspot/hotspot_server_screen.dart';
import '../../features/hotspot/hotspot_setup_summary_screen.dart';
import '../../features/hotspot/hotspot_profile_editor_screen.dart';
import '../../features/hotspot/hotspot_cookie_login_audit_screen.dart';
import '../../features/hotspot/hotspot_cookie_expiry_audit_screen.dart';
import '../../features/hotspot/hotspot_expired_cleanup_screen.dart';
import '../../features/hotspot/hotspot_expiry_preview_screen.dart';
import '../../features/hotspot/hotspot_expiry_summary_screen.dart';
import '../../features/backup/router_files_screen.dart';
import '../../features/backup/router_export_screen.dart';
import '../../features/backup/router_files_manager_screen.dart';
import '../../features/backup/router_backup_manager_screen.dart';
import '../../features/backup/app_backup_screen.dart';
import '../../features/discovery/router_candidate_save_screen.dart';
import '../../features/discovery/ip_scan_screen.dart';
import '../../features/discovery/romon_discovery_screen.dart';
import '../../features/discovery/vpn_discovery_screen.dart';
import '../../features/discovery/neighbor_inventory_screen.dart';
import '../../features/network/interface_editor_screen.dart';
import '../../features/network/interface_list_member_editor_screen.dart';
import '../../features/network/interface_list_editor_screen.dart';
import '../../features/network/route_detail_screen.dart';
import '../../features/network/ip_route_editor_screen.dart';
import '../../features/vpn/wireguard_peers_screen.dart';
import '../../features/vpn/wireguard_interface_editor_screen.dart';
import '../../features/queues/queue_detail_screen.dart';
import '../../features/queues/queue_monitor_settings_screen.dart';
import '../../features/firewall/internet_sharing_list_screen.dart';
import '../../features/firewall/firewall_rules_screen.dart';
import '../../features/system/script_detail_screen.dart';
import '../../features/system/system_script_editor_screen.dart';
import '../../features/system/scheduler_detail_screen.dart';
import '../../features/system/system_scheduler_editor_screen.dart';
import '../../features/monitoring/router_connection_status_screen.dart';
import '../../features/monitoring/torch_screen.dart';
import '../../features/monitoring/interface_monitor_screen.dart';
import '../../features/ppp/ppp_profile_editor_screen.dart';
import '../../features/ppp/ppp_secret_editor_screen.dart';
import '../../features/ppp/ppp_active_detail_screen.dart';
import '../../features/ppp/ppp_monitor_settings_screen.dart';
import '../../features/vouchers/voucher_generation_result_screen.dart';
import '../../features/vouchers/voucher_print_screen.dart';
import '../../features/hotspot/hotspot_monitor_settings_screen.dart';
import '../../features/hotspot/hotspot_host_detail_screen.dart';
import '../../features/hotspot/hotspot_ip_binding_editor_screen.dart';
import '../../features/hotspot/hotspot_users_export_screen.dart';
import '../../features/hotspot/hotspot_add_user_screen.dart';
import '../../features/hotspot/hotspot_user_editor_screen.dart';
import 'navigation_payloads.dart';

/// Routeur racine ACTIF pendant la migration progressive.
///
/// `DashboardScreen` est la racine déclarative. La navigation applicative utilise des routes nommées explicites par domaine.
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static GoRouter build() {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoutePaths.dashboard,
      routes: [
        GoRoute(
          path: AppRoutePaths.dashboard,
          name: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),

        GoRoute(
          path: AppRoutePaths.routers,
          name: AppRoutes.routers,
          builder: (context, state) => const RoutersScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.settings,
          name: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.audit,
          name: AppRoutes.audit,
          builder: (context, state) => const AuditScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.dhcp,
          name: AppRoutes.dhcp,
          builder: (context, state) => _requireRouter(
            'DHCP',
            () => DhcpHubScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.dns,
          name: AppRoutes.dns,
          builder: (context, state) => _requireRouter(
            'DNS',
            () => DnsHubScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.interfaces,
          name: AppRoutes.interfaces,
          builder: (context, state) => _requireRouter(
            'Interfaces',
            () => InterfacesHubScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.firewall,
          name: AppRoutes.firewall,
          builder: (context, state) => _requireRouter(
            'Firewall',
            () => FirewallAdvancedHubScreen(
              service: RouterSession.instance.service,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.nat,
          name: AppRoutes.nat,
          builder: (context, state) => _requireRouter(
            'NAT',
            () => const h2.FirewallManagementScreen(
              title: 'Firewall NAT',
              path: '/ip/firewall/nat',
            ),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.queues,
          name: AppRoutes.queues,
          builder: (context, state) => _requireRouter(
            'Queues',
            () => QueuesHubScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.traffic,
          name: AppRoutes.traffic,
          builder: (context, state) =>
              _requireRouter('Traffic', () => const MonitoringHubScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.wireless,
          name: AppRoutes.wireless,
          builder: (context, state) => _requireRouter(
            'Wireless',
            () => WirelessHubScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.neighbors,
          name: AppRoutes.neighbors,
          builder: (context, state) => _requireRouter(
            'Voisinage',
            () => DiscoveryScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.networkScan,
          name: AppRoutes.networkScan,
          builder: (context, state) =>
              _requireRouter('Scan réseau', () => const IpScanScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.tools,
          name: AppRoutes.tools,
          builder: (context, state) => _requireRouter(
            'Tools',
            () => NetworkToolsScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.scripts,
          name: AppRoutes.scripts,
          builder: (context, state) =>
              _requireRouter('Scripts', () => const ScriptsScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.scheduler,
          name: AppRoutes.scheduler,
          builder: (context, state) =>
              _requireRouter('Scheduler', () => const SchedulerScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.logs,
          name: AppRoutes.logs,
          builder: (context, state) =>
              _requireRouter('Logs', () => const LogsScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.backup,
          name: AppRoutes.backup,
          builder: (context, state) =>
              _requireRouter('Backup', () => const BackupHubScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.system,
          name: AppRoutes.system,
          builder: (context, state) => _requireRouter(
            'Système',
            () => SystemHubScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspot,
          name: AppRoutes.hotspot,
          builder: (context, state) => _requireRouter(
            'Hotspot',
            () => HotspotManagementScreen(
              service: RouterSession.instance.service,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.vouchers,
          name: AppRoutes.vouchers,
          builder: (context, state) => _requireRouter(
            'Vouchers',
            () => VoucherGeneratorScreen(
              service: RouterSession.instance.service,
              routerId: RouterSession.instance.activeRouter?.id,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.ppp,
          name: AppRoutes.ppp,
          builder: (context, state) => _requireRouter(
            'PPPoE',
            () => PppHubScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.reports,
          name: AppRoutes.reports,
          builder: (context, state) => _requireRouter(
            'Reports',
            () => ReportsScreen(service: RouterSession.instance.service),
          ),
        ),

        GoRoute(
          path: AppRoutePaths.hotspotSettings,
          name: AppRoutes.hotspotSettings,
          builder: (context, state) =>
              HotspotSettingsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotWinbox,
          name: AppRoutes.hotspotWinbox,
          builder: (context, state) => _requireRouter(
            'Hotspot — WinBox',
            () => const HotspotWinboxScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotWinboxUsers,
          name: AppRoutes.hotspotWinboxUsers,
          builder: (context, state) => _requireRouter(
            'Hotspot Users',
            () => HotspotUsersScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotWinboxProfiles,
          name: AppRoutes.hotspotWinboxProfiles,
          builder: (context, state) => _requireRouter(
            'Hotspot User Profiles',
            () => HotspotManagementScreen(
              service: RouterSession.instance.service,
              initialIndex: 1,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotWinboxRuntime,
          name: AppRoutes.hotspotWinboxRuntime,
          builder: (context, state) => _requireRouter(
            'Hotspot Runtime',
            () =>
                HotspotAdvancedScreen(service: RouterSession.instance.service),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.voucherOperations,
          name: AppRoutes.voucherOperations,
          builder: (context, state) => VoucherOperationsHubScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.pppActive,
          name: AppRoutes.pppActive,
          builder: (context, state) =>
              PppActiveScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.pppExport,
          name: AppRoutes.pppExport,
          builder: (context, state) =>
              PppExportScreen(service: RouterSession.instance.service),
        ),

        GoRoute(
          path: AppRoutePaths.hotspotUserEdit,
          name: AppRoutes.hotspotUserEdit,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! HotspotUserPayload) {
              return const _MissingPayloadScreen();
            }
            return HotspotUserEditorScreen(
              service: RouterSession.instance.service,
              user: payload.user,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.hotspotUserAdd,
          name: AppRoutes.hotspotUserAdd,
          builder: (context, state) {
            final payload = state.extra;
            return HotspotAddUserScreen(
              service: RouterSession.instance.service,
              initialProfile: payload is HotspotAddUserPayload
                  ? payload.initialProfile
                  : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.hotspotUsersExport,
          name: AppRoutes.hotspotUsersExport,
          builder: (context, state) =>
              HotspotUsersExportScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotIpBindingEdit,
          name: AppRoutes.hotspotIpBindingEdit,
          builder: (context, state) {
            final payload = state.extra;
            return HotspotIpBindingEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.hotspotHostDetail,
          name: AppRoutes.hotspotHostDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! HotspotHostPayload) {
              return const _MissingPayloadScreen();
            }
            return HotspotHostDetailScreen(
              service: RouterSession.instance.service,
              host: payload.host,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.hotspotMonitorSettings,
          name: AppRoutes.hotspotMonitorSettings,
          builder: (context, state) => const HotspotMonitorSettingsScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.voucherPrint,
          name: AppRoutes.voucherPrint,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! VoucherPrintPayload) {
              return const _MissingPayloadScreen();
            }
            return VoucherPrintScreen(
              vouchers: payload.vouchers,
              layout: payload.layout,
              templateSettings: payload.templateSettings,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.voucherGenerationResult,
          name: AppRoutes.voucherGenerationResult,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! VoucherGenerationResultPayload) {
              return const _MissingPayloadScreen();
            }
            return VoucherGenerationResultScreen(result: payload.result);
          },
        ),
        GoRoute(
          path: AppRoutePaths.pppMonitorSettings,
          name: AppRoutes.pppMonitorSettings,
          builder: (context, state) => const PppMonitorSettingsScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.pppActiveDetail,
          name: AppRoutes.pppActiveDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! PppActivePayload) {
              return const _MissingPayloadScreen();
            }
            return PppActiveDetailScreen(row: payload.row);
          },
        ),
        GoRoute(
          path: AppRoutePaths.pppSecretEdit,
          name: AppRoutes.pppSecretEdit,
          builder: (context, state) {
            final payload = state.extra;
            return PppSecretEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.pppProfileEdit,
          name: AppRoutes.pppProfileEdit,
          builder: (context, state) {
            final payload = state.extra;
            return PppProfileEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),

        GoRoute(
          path: AppRoutePaths.monitorInterfaces,
          name: AppRoutes.monitorInterfaces,
          builder: (context, state) {
            final payload = state.extra;
            return InterfaceMonitorScreen(
              service: RouterSession.instance.service,
              initialInterface: payload is InterfaceMonitorPayload
                  ? payload.interfaceName
                  : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.monitorTorch,
          name: AppRoutes.monitorTorch,
          builder: (context, state) => const TorchScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.monitorConnection,
          name: AppRoutes.monitorConnection,
          builder: (context, state) => const RouterConnectionStatusScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.schedulerEdit,
          name: AppRoutes.schedulerEdit,
          builder: (context, state) {
            final payload = state.extra;
            return SystemSchedulerEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.schedulerDetail,
          name: AppRoutes.schedulerDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return SchedulerDetailScreen(
              service: RouterSession.instance.service,
              row: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.scriptEdit,
          name: AppRoutes.scriptEdit,
          builder: (context, state) {
            final payload = state.extra;
            return SystemScriptEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.scriptDetail,
          name: AppRoutes.scriptDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return ScriptDetailScreen(
              service: RouterSession.instance.service,
              row: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.firewallMangleRules,
          name: AppRoutes.firewallMangleRules,
          builder: (context, state) => FirewallRulesScreen(
            service: RouterSession.instance.service,
            path: '/ip/firewall/mangle',
            title: 'Règles Mangle',
          ),
        ),
        GoRoute(
          path: AppRoutePaths.internetSharing,
          name: AppRoutes.internetSharing,
          builder: (context, state) => InternetSharingListScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.queueMonitorSettings,
          name: AppRoutes.queueMonitorSettings,
          builder: (context, state) => const QueueMonitorSettingsScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.queueDetail,
          name: AppRoutes.queueDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! QueueDetailPayload) {
              return const _MissingPayloadScreen();
            }
            return QueueDetailScreen(title: payload.title, row: payload.row);
          },
        ),
        GoRoute(
          path: AppRoutePaths.wireguardInterfaceEdit,
          name: AppRoutes.wireguardInterfaceEdit,
          builder: (context, state) {
            final payload = state.extra;
            return WireGuardInterfaceEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.wireguardPeers,
          name: AppRoutes.wireguardPeers,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! WireGuardPeersPayload) {
              return const _MissingPayloadScreen();
            }
            return WireGuardPeersScreen(
              service: RouterSession.instance.service,
              interfaceName: payload.interfaceName,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.ipAddressEdit,
          name: AppRoutes.ipAddressEdit,
          builder: (context, state) {
            final payload = state.extra;
            return IpAddressEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.ipRouteEdit,
          name: AppRoutes.ipRouteEdit,
          builder: (context, state) {
            final payload = state.extra;
            return IpRouteEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.ipRouteDetail,
          name: AppRoutes.ipRouteDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return RouteDetailScreen(
              service: RouterSession.instance.service,
              row: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.interfaceListEdit,
          name: AppRoutes.interfaceListEdit,
          builder: (context, state) {
            final payload = state.extra;
            return InterfaceListEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.interfaceListMemberEdit,
          name: AppRoutes.interfaceListMemberEdit,
          builder: (context, state) {
            final payload = state.extra;
            return InterfaceListMemberEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.interfaceEdit,
          name: AppRoutes.interfaceEdit,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return InterfaceEditorScreen(
              service: RouterSession.instance.service,
              row: payload.row,
            );
          },
        ),

        GoRoute(
          path: AppRoutePaths.discoveryNeighbors,
          name: AppRoutes.discoveryNeighbors,
          builder: (context, state) =>
              NeighborInventoryScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.discoveryVpn,
          name: AppRoutes.discoveryVpn,
          builder: (context, state) =>
              VpnDiscoveryScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.discoveryRomon,
          name: AppRoutes.discoveryRomon,
          builder: (context, state) =>
              RomonDiscoveryScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.discoveryIpScan,
          name: AppRoutes.discoveryIpScan,
          builder: (context, state) => const IpScanScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.discoveryCandidateSave,
          name: AppRoutes.discoveryCandidateSave,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! DiscoveryCandidatePayload) {
              return const _MissingPayloadScreen();
            }
            return RouterCandidateSaveScreen(candidate: payload.candidate);
          },
        ),
        GoRoute(
          path: AppRoutePaths.backupApp,
          name: AppRoutes.backupApp,
          builder: (context, state) => const AppBackupScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.backupRouter,
          name: AppRoutes.backupRouter,
          builder: (context, state) => RouterBackupManagerScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.backupRouterFiles,
          name: AppRoutes.backupRouterFiles,
          builder: (context, state) =>
              RouterFilesManagerScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.backupRouterExport,
          name: AppRoutes.backupRouterExport,
          builder: (context, state) =>
              RouterExportScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.backupLegacyFiles,
          name: AppRoutes.backupLegacyFiles,
          builder: (context, state) =>
              RouterFilesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotExpirySummary,
          name: AppRoutes.hotspotExpirySummary,
          builder: (context, state) => HotspotExpirySummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotExpiryPreview,
          name: AppRoutes.hotspotExpiryPreview,
          builder: (context, state) => HotspotExpiryPreviewScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotExpiryCleanup,
          name: AppRoutes.hotspotExpiryCleanup,
          builder: (context, state) => HotspotExpiredCleanupScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotCookieExpiryAudit,
          name: AppRoutes.hotspotCookieExpiryAudit,
          builder: (context, state) => HotspotCookieExpiryAuditScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotCookieLoginAudit,
          name: AppRoutes.hotspotCookieLoginAudit,
          builder: (context, state) => HotspotCookieLoginAuditScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotProfileEdit,
          name: AppRoutes.hotspotProfileEdit,
          builder: (context, state) {
            final payload = state.extra;
            return HotspotProfileEditorScreen(
              service: RouterSession.instance.service,
              profile: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.hotspotSetupSummary,
          name: AppRoutes.hotspotSetupSummary,
          builder: (context, state) => HotspotSetupSummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotServers,
          name: AppRoutes.hotspotServers,
          builder: (context, state) =>
              HotspotServerScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotServerProfiles,
          name: AppRoutes.hotspotServerProfiles,
          builder: (context, state) => HotspotServerProfileScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotIpPools,
          name: AppRoutes.hotspotIpPools,
          builder: (context, state) =>
              IpPoolScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotActive,
          name: AppRoutes.hotspotActive,
          builder: (context, state) =>
              HotspotActiveScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hotspotServerProfileEdit,
          name: AppRoutes.hotspotServerProfileEdit,
          builder: (context, state) {
            final payload = state.extra;
            return HotspotServerProfileEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.hotspotServerEdit,
          name: AppRoutes.hotspotServerEdit,
          builder: (context, state) {
            final payload = state.extra;
            return HotspotServerEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.hotspotIpPoolEdit,
          name: AppRoutes.hotspotIpPoolEdit,
          builder: (context, state) {
            final payload = state.extra;
            return IpPoolEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.networkArpEdit,
          name: AppRoutes.networkArpEdit,
          builder: (context, state) {
            final payload = state.extra;
            return ArpEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.internetSharingAdd,
          name: AppRoutes.internetSharingAdd,
          builder: (context, state) =>
              InternetSharingAddScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.bridgeEdit,
          name: AppRoutes.bridgeEdit,
          builder: (context, state) => BridgeEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.bridgeVlanActivation,
          name: AppRoutes.bridgeVlanActivation,
          builder: (context, state) {
            if (state.extra is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return BridgeVlanActivationScreen(
              service: RouterSession.instance.service,
              bridge: (state.extra as RequiredRowPayload).row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.bridgePortEdit,
          name: AppRoutes.bridgePortEdit,
          builder: (context, state) {
            if (state.extra is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return BridgePortEditorScreen(
              service: RouterSession.instance.service,
              row: (state.extra as RequiredRowPayload).row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.bridgeVlanEdit,
          name: AppRoutes.bridgeVlanEdit,
          builder: (context, state) => BridgeVlanEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.dhcpLeaseEdit,
          name: AppRoutes.dhcpLeaseEdit,
          builder: (context, state) => DhcpLeaseEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.dhcpNetworkEdit,
          name: AppRoutes.dhcpNetworkEdit,
          builder: (context, state) => DhcpNetworkEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.dhcpServerEdit,
          name: AppRoutes.dhcpServerEdit,
          builder: (context, state) => DhcpServerEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.dnsStaticEdit,
          name: AppRoutes.dnsStaticEdit,
          builder: (context, state) => DnsStaticEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.ipv6AddressEdit,
          name: AppRoutes.ipv6AddressEdit,
          builder: (context, state) => Ipv6AddressEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.ipv6RouteEdit,
          name: AppRoutes.ipv6RouteEdit,
          builder: (context, state) => Ipv6RouteEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.routingRuleEdit,
          name: AppRoutes.routingRuleEdit,
          builder: (context, state) => RoutingRuleEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.routingTableEdit,
          name: AppRoutes.routingTableEdit,
          builder: (context, state) => RoutingTableEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.vlanEdit,
          name: AppRoutes.vlanEdit,
          builder: (context, state) => VlanEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.wifiProvisioningEdit,
          name: AppRoutes.wifiProvisioningEdit,
          builder: (context, state) => WifiProvisioningEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.zeroTierInterfaceEdit,
          name: AppRoutes.zeroTierInterfaceEdit,
          builder: (context, state) => ZeroTierInterfaceEditorScreen(
            service: RouterSession.instance.service,
            row: state.extra is OptionalRowPayload
                ? (state.extra as OptionalRowPayload).row
                : null,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.bridgePorts,
          name: AppRoutes.bridgePorts,
          builder: (context, state) =>
              BridgePortsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.bridgeVlanTable,
          name: AppRoutes.bridgeVlanTable,
          builder: (context, state) =>
              BridgeVlanTableScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.bridgeHosts,
          name: AppRoutes.bridgeHosts,
          builder: (context, state) =>
              BridgeHostsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.interfaceLists,
          name: AppRoutes.interfaceLists,
          builder: (context, state) =>
              InterfaceListsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.bridgeVlanSafety,
          name: AppRoutes.bridgeVlanSafety,
          builder: (context, state) =>
              BridgeVlanSafetyScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.bridgeVlanCapability,
          name: AppRoutes.bridgeVlanCapability,
          builder: (context, state) => BridgeVlanCapabilityScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.dhcpSummary,
          name: AppRoutes.dhcpSummary,
          builder: (context, state) =>
              DhcpSummaryScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.dhcpServersList,
          name: AppRoutes.dhcpServersList,
          builder: (context, state) =>
              DhcpServersScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.dhcpNetworksList,
          name: AppRoutes.dhcpNetworksList,
          builder: (context, state) =>
              DhcpNetworksScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.dhcpLeasesList,
          name: AppRoutes.dhcpLeasesList,
          builder: (context, state) => DhcpLeasesManagementScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.dnsSummary,
          name: AppRoutes.dnsSummary,
          builder: (context, state) =>
              DnsSummaryScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.dnsSettings,
          name: AppRoutes.dnsSettings,
          builder: (context, state) =>
              DnsSettingsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.dnsStaticList,
          name: AppRoutes.dnsStaticList,
          builder: (context, state) =>
              DnsStaticScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.dnsCache,
          name: AppRoutes.dnsCache,
          builder: (context, state) =>
              DnsCacheScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.dnsAdlist,
          name: AppRoutes.dnsAdlist,
          builder: (context, state) =>
              DnsAdlistScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.dnsDiagnostics,
          name: AppRoutes.dnsDiagnostics,
          builder: (context, state) =>
              DnsDiagnosticsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.routingSummary,
          name: AppRoutes.routingSummary,
          builder: (context, state) =>
              RoutingSummaryScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.ipRoutesList,
          name: AppRoutes.ipRoutesList,
          builder: (context, state) =>
              IpRoutesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.arpList,
          name: AppRoutes.arpList,
          builder: (context, state) =>
              ArpScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.ipAddresses,
          name: AppRoutes.ipAddresses,
          builder: (context, state) =>
              IpAddressesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.ipNeighbors,
          name: AppRoutes.ipNeighbors,
          builder: (context, state) =>
              IpNeighborsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.vpnSummary,
          name: AppRoutes.vpnSummary,
          builder: (context, state) =>
              VpnSummaryScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.vpnWireGuardInterfaces,
          name: AppRoutes.vpnWireGuardInterfaces,
          builder: (context, state) => WireGuardInterfacesScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.vpnZeroTier,
          name: AppRoutes.vpnZeroTier,
          builder: (context, state) =>
              ZeroTierScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.vpnBackToHome,
          name: AppRoutes.vpnBackToHome,
          builder: (context, state) =>
              BackToHomeScreen(service: RouterSession.instance.service),
        ),

        GoRoute(
          path: AppRoutePaths.firewallRuleEdit,
          name: AppRoutes.firewallRuleEdit,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! FirewallRulePayload) {
              return const _MissingPayloadScreen();
            }
            return FirewallRuleEditorScreen(
              service: RouterSession.instance.service,
              path: payload.path,
              title: payload.title,
              row: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.firewallAdvancedRuleEdit,
          name: AppRoutes.firewallAdvancedRuleEdit,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! FirewallAdvancedRulePayload) {
              return const _MissingPayloadScreen();
            }
            final service = RouterSession.instance.service;
            if (payload.path.endsWith('/filter')) {
              return FilterRuleEditorScreen(service: service, row: payload.row);
            }
            if (payload.path.endsWith('/nat')) {
              return NatRuleEditorScreen(service: service, row: payload.row);
            }
            if (payload.path.endsWith('/mangle')) {
              return MangleRuleEditorScreen(service: service, row: payload.row);
            }
            return RawRuleEditorScreen(service: service, row: payload.row);
          },
        ),
        GoRoute(
          path: AppRoutePaths.interfaceDetail,
          name: AppRoutes.interfaceDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return InterfaceDetailScreen(
              service: RouterSession.instance.service,
              row: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.wifiAccessRuleEdit,
          name: AppRoutes.wifiAccessRuleEdit,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! WifiAccessRulePayload) {
              return const _MissingPayloadScreen();
            }
            return WifiAccessRuleEditorScreen(
              service: RouterSession.instance.service,
              backend: payload.backend,
              row: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.wifiProfileEdit,
          name: AppRoutes.wifiProfileEdit,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! WifiProfilePayload) {
              return const _MissingPayloadScreen();
            }
            return WifiProfileEditorScreen(
              service: RouterSession.instance.service,
              kind: payload.kind,
              row: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.wireGuardPeerEditNetwork,
          name: AppRoutes.wireGuardPeerEditNetwork,
          builder: (context, state) {
            final payload = state.extra;
            return WireGuardPeerEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.wirelessDetail,
          name: AppRoutes.wirelessDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return WirelessDetailScreen(
              service: RouterSession.instance.service,
              row: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.queueTreeEdit,
          name: AppRoutes.queueTreeEdit,
          builder: (context, state) {
            final payload = state.extra;
            return QueueTreeEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.queueTypeEdit,
          name: AppRoutes.queueTypeEdit,
          builder: (context, state) {
            final payload = state.extra;
            return QueueTypeEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.simpleQueueEdit,
          name: AppRoutes.simpleQueueEdit,
          builder: (context, state) {
            final payload = state.extra;
            return SimpleQueueEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.loggingActionEdit,
          name: AppRoutes.loggingActionEdit,
          builder: (context, state) {
            final payload = state.extra;
            return LoggingActionEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.logDetail,
          name: AppRoutes.logDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return LogDetailScreen(row: payload.row);
          },
        ),
        GoRoute(
          path: AppRoutePaths.loggingRuleEdit,
          name: AppRoutes.loggingRuleEdit,
          builder: (context, state) {
            final payload = state.extra;
            return LoggingRuleEditorScreen(
              service: RouterSession.instance.service,
              row: payload is OptionalRowPayload ? payload.row : null,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.voucherTemplateEditor,
          name: AppRoutes.voucherTemplateEditor,
          builder: (context, state) => const VoucherTemplateEditorScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.routerConnection,
          name: AppRoutes.routerConnection,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! RouterConnectionPayload) {
              return const _MissingPayloadScreen();
            }
            return RouterConnectionScreen(router: payload.router);
          },
        ),
        GoRoute(
          path: AppRoutePaths.hubFirewallRulesFilter,
          name: AppRoutes.hubFirewallRulesFilter,
          builder: (context, state) => h3.FirewallRulesScreen(
            service: RouterSession.instance.service,
            path: '/ip/firewall/filter',
            title: 'Filter Rules',
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubFirewallRulesNat,
          name: AppRoutes.hubFirewallRulesNat,
          builder: (context, state) => h3.FirewallRulesScreen(
            service: RouterSession.instance.service,
            path: '/ip/firewall/nat',
            title: 'NAT',
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubMangleTools,
          name: AppRoutes.hubMangleTools,
          builder: (context, state) =>
              h5.MangleToolsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubFirewallRulesRaw,
          name: AppRoutes.hubFirewallRulesRaw,
          builder: (context, state) => h3.FirewallRulesScreen(
            service: RouterSession.instance.service,
            path: '/ip/firewall/raw',
            title: 'RAW',
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubFirewallAddressList,
          name: AppRoutes.hubFirewallAddressList,
          builder: (context, state) => h1.FirewallAddressListScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubFirewallStats,
          name: AppRoutes.hubFirewallStats,
          builder: (context, state) =>
              h4.FirewallStatsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubFirewallManagementFilter,
          name: AppRoutes.hubFirewallManagementFilter,
          builder: (context, state) => const h2.FirewallManagementScreen(
            title: 'Filter Rules',
            path: '/ip/firewall/filter',
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubFirewallManagementNat,
          name: AppRoutes.hubFirewallManagementNat,
          builder: (context, state) => const h2.FirewallManagementScreen(
            title: 'NAT',
            path: '/ip/firewall/nat',
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubFirewallManagementMangle,
          name: AppRoutes.hubFirewallManagementMangle,
          builder: (context, state) => const h2.FirewallManagementScreen(
            title: 'Mangle',
            path: '/ip/firewall/mangle',
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVpnAdvancedHub,
          name: AppRoutes.hubVpnAdvancedHub,
          builder: (context, state) =>
              h27.VpnAdvancedHubScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubInterfacesManagement,
          name: AppRoutes.hubInterfacesManagement,
          builder: (context, state) => h14.InterfacesManagementScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubInterfaceMonitor,
          name: AppRoutes.hubInterfaceMonitor,
          builder: (context, state) => h7.InterfaceMonitorScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVlan,
          name: AppRoutes.hubVlan,
          builder: (context, state) =>
              h26.VlanScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubBridgeManagement,
          name: AppRoutes.hubBridgeManagement,
          builder: (context, state) => h11.BridgeManagementScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubBridgeVlanHub,
          name: AppRoutes.hubBridgeVlanHub,
          builder: (context, state) =>
              h12.BridgeVlanHubScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubRoutingIpHub,
          name: AppRoutes.hubRoutingIpHub,
          builder: (context, state) =>
              h21.RoutingIpHubScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubBridgeHosts,
          name: AppRoutes.hubBridgeHosts,
          builder: (context, state) =>
              h10.BridgeHostsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubInterfaceLists,
          name: AppRoutes.hubInterfaceLists,
          builder: (context, state) =>
              h13.InterfaceListsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubIpAddresses,
          name: AppRoutes.hubIpAddresses,
          builder: (context, state) =>
              h15.IpAddressesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubRoutingPolicySummary,
          name: AppRoutes.hubRoutingPolicySummary,
          builder: (context, state) => h23.RoutingPolicySummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubRoutingTables,
          name: AppRoutes.hubRoutingTables,
          builder: (context, state) =>
              h25.RoutingTablesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubRoutingRules,
          name: AppRoutes.hubRoutingRules,
          builder: (context, state) =>
              h24.RoutingRulesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubVrf,
          name: AppRoutes.hubVrf,
          builder: (context, state) =>
              h31.VrfScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubIpv6Inventory,
          name: AppRoutes.hubIpv6Inventory,
          builder: (context, state) =>
              h17.Ipv6InventoryScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubIpv6Addresses,
          name: AppRoutes.hubIpv6Addresses,
          builder: (context, state) =>
              h16.Ipv6AddressesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubIpv6Routes,
          name: AppRoutes.hubIpv6Routes,
          builder: (context, state) =>
              h19.Ipv6RoutesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubIpv6Nd,
          name: AppRoutes.hubIpv6Nd,
          builder: (context, state) =>
              h18.Ipv6NdScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubRoutingPolicySafety,
          name: AppRoutes.hubRoutingPolicySafety,
          builder: (context, state) => h22.RoutingPolicySafetyScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVpnIntegrationSummary,
          name: AppRoutes.hubVpnIntegrationSummary,
          builder: (context, state) => h29.VpnIntegrationSummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWireGuardInterfaces,
          name: AppRoutes.hubWireGuardInterfaces,
          builder: (context, state) => h39.WireGuardInterfacesScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWireGuardPeers,
          name: AppRoutes.hubWireGuardPeers,
          builder: (context, state) =>
              h40.WireGuardPeersScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubZeroTierInterfaces,
          name: AppRoutes.hubZeroTierInterfaces,
          builder: (context, state) => h46.ZeroTierInterfacesScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubZeroTierPeers,
          name: AppRoutes.hubZeroTierPeers,
          builder: (context, state) =>
              h47.ZeroTierPeersScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubBackToHomeStatus,
          name: AppRoutes.hubBackToHomeStatus,
          builder: (context, state) => h8.BackToHomeStatusScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubBackToHomeUsers,
          name: AppRoutes.hubBackToHomeUsers,
          builder: (context, state) =>
              h9.BackToHomeUsersScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubVpnNeighborCandidates,
          name: AppRoutes.hubVpnNeighborCandidates,
          builder: (context, state) => h30.VpnNeighborCandidatesScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVpnCapabilityStatus,
          name: AppRoutes.hubVpnCapabilityStatus,
          builder: (context, state) => h28.VpnCapabilityStatusScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWifiConfigSummary,
          name: AppRoutes.hubWifiConfigSummary,
          builder: (context, state) => h36.WifiConfigSummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWifiAccessListModern,
          name: AppRoutes.hubWifiAccessListModern,
          builder: (context, state) => h32.WifiAccessListScreen(
            service: RouterSession.instance.service,
            backend: hub_backend.WifiConfigBackend.modern,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWifiAccessListLegacy,
          name: AppRoutes.hubWifiAccessListLegacy,
          builder: (context, state) => h32.WifiAccessListScreen(
            service: RouterSession.instance.service,
            backend: hub_backend.WifiConfigBackend.legacy,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubLegacyConnectList,
          name: AppRoutes.hubLegacyConnectList,
          builder: (context, state) => h20.LegacyConnectListScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWifiProfiles,
          name: AppRoutes.hubWifiProfiles,
          builder: (context, state) =>
              h37.WifiProfilesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubWifiCapsman,
          name: AppRoutes.hubWifiCapsman,
          builder: (context, state) =>
              h34.WifiCapsmanScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubWifiProvisioning,
          name: AppRoutes.hubWifiProvisioning,
          builder: (context, state) => h38.WifiProvisioningScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWifiAclSafety,
          name: AppRoutes.hubWifiAclSafety,
          builder: (context, state) =>
              h33.WifiAclSafetyScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubWirelessSummary,
          name: AppRoutes.hubWirelessSummary,
          builder: (context, state) => h45.WirelessSummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWirelessInventory,
          name: AppRoutes.hubWirelessInventory,
          builder: (context, state) => h41.WirelessInventoryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWirelessRegistration,
          name: AppRoutes.hubWirelessRegistration,
          builder: (context, state) => h42.WirelessRegistrationScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWirelessSecurity,
          name: AppRoutes.hubWirelessSecurity,
          builder: (context, state) => h44.WirelessSecurityScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubWirelessScan,
          name: AppRoutes.hubWirelessScan,
          builder: (context, state) =>
              h43.WirelessScanScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubWifiConfigHub,
          name: AppRoutes.hubWifiConfigHub,
          builder: (context, state) =>
              h35.WifiConfigHubScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppManagement,
          name: AppRoutes.hubPppManagement,
          builder: (context, state) =>
              h52.PppManagementScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppActive,
          name: AppRoutes.hubPppActive,
          builder: (context, state) =>
              h48.PppActiveScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppoeServer,
          name: AppRoutes.hubPppoeServer,
          builder: (context, state) =>
              h62.PppoeServerScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppInterfaces,
          name: AppRoutes.hubPppInterfaces,
          builder: (context, state) =>
              h51.PppInterfacesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppExport,
          name: AppRoutes.hubPppExport,
          builder: (context, state) =>
              h50.PppExportScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppSafetyAudit,
          name: AppRoutes.hubPppSafetyAudit,
          builder: (context, state) =>
              h56.PppSafetyAuditScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppProfileUsage,
          name: AppRoutes.hubPppProfileUsage,
          builder: (context, state) => h55.PppProfileUsageScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppSecretHealth,
          name: AppRoutes.hubPppSecretHealth,
          builder: (context, state) => h58.PppSecretHealthScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppOrphanSession,
          name: AppRoutes.hubPppOrphanSession,
          builder: (context, state) => h53.PppOrphanSessionScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppUnusedProfile,
          name: AppRoutes.hubPppUnusedProfile,
          builder: (context, state) => h61.PppUnusedProfileScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppProfileConsistency,
          name: AppRoutes.hubPppProfileConsistency,
          builder: (context, state) => h54.PppProfileConsistencyScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppSecretConsistency,
          name: AppRoutes.hubPppSecretConsistency,
          builder: (context, state) => h57.PppSecretConsistencyScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppSecretSafetySummary,
          name: AppRoutes.hubPppSecretSafetySummary,
          builder: (context, state) => h59.PppSecretSafetySummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppSoftwareReadiness,
          name: AppRoutes.hubPppSoftwareReadiness,
          builder: (context, state) => const h60.PppSoftwareReadinessScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.hubPppDestructiveActionAudit,
          name: AppRoutes.hubPppDestructiveActionAudit,
          builder: (context, state) => h49.PppDestructiveActionAuditScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubSimpleQueue,
          name: AppRoutes.hubSimpleQueue,
          builder: (context, state) =>
              h67.SimpleQueueScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubQueueTree,
          name: AppRoutes.hubQueueTree,
          builder: (context, state) =>
              h65.QueueTreeScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubQueueType,
          name: AppRoutes.hubQueueType,
          builder: (context, state) =>
              h66.QueueTypeScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubQueueMonitor,
          name: AppRoutes.hubQueueMonitor,
          builder: (context, state) =>
              h63.QueueMonitorScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubQueueStats,
          name: AppRoutes.hubQueueStats,
          builder: (context, state) =>
              h64.QueueStatsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubAutomationSummary,
          name: AppRoutes.hubAutomationSummary,
          builder: (context, state) => h69.AutomationSummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubScriptsManagement,
          name: AppRoutes.hubScriptsManagement,
          builder: (context, state) => h84.ScriptsManagementScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubScriptJobs,
          name: AppRoutes.hubScriptJobs,
          builder: (context, state) =>
              h82.ScriptJobsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSchedulerManagement,
          name: AppRoutes.hubSchedulerManagement,
          builder: (context, state) => h81.SchedulerManagementScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubSchedulerLinkage,
          name: AppRoutes.hubSchedulerLinkage,
          builder: (context, state) => h80.SchedulerLinkageScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubScriptPermissions,
          name: AppRoutes.hubScriptPermissions,
          builder: (context, state) => const h83.ScriptPermissionsScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.hubLoggingSummary,
          name: AppRoutes.hubLoggingSummary,
          builder: (context, state) =>
              h78.LoggingSummaryScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubLogsManagement,
          name: AppRoutes.hubLogsManagement,
          builder: (context, state) =>
              h79.LogsManagementScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubLoggingBuffers,
          name: AppRoutes.hubLoggingBuffers,
          builder: (context, state) =>
              h73.LoggingBuffersScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubLoggingRules,
          name: AppRoutes.hubLoggingRules,
          builder: (context, state) =>
              h77.LoggingRulesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubLoggingActions,
          name: AppRoutes.hubLoggingActions,
          builder: (context, state) =>
              h72.LoggingActionsScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubLoggingDiagnostics,
          name: AppRoutes.hubLoggingDiagnostics,
          builder: (context, state) => h74.LoggingDiagnosticsScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubLoggingExport,
          name: AppRoutes.hubLoggingExport,
          builder: (context, state) =>
              h75.LoggingExportScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemSecurityHub,
          name: AppRoutes.hubSystemSecurityHub,
          builder: (context, state) => h91.SystemSecurityHubScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemOverview,
          name: AppRoutes.hubSystemOverview,
          builder: (context, state) =>
              h89.SystemOverviewScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemHealth,
          name: AppRoutes.hubSystemHealth,
          builder: (context, state) =>
              h86.SystemHealthScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemStorage,
          name: AppRoutes.hubSystemStorage,
          builder: (context, state) =>
              h93.SystemStorageScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemPackages,
          name: AppRoutes.hubSystemPackages,
          builder: (context, state) =>
              h90.SystemPackagesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemNtp,
          name: AppRoutes.hubSystemNtp,
          builder: (context, state) =>
              h88.SystemNtpScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubAutomationHub,
          name: AppRoutes.hubAutomationHub,
          builder: (context, state) =>
              h68.AutomationHubScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubLoggingHub,
          name: AppRoutes.hubLoggingHub,
          builder: (context, state) =>
              h76.LoggingHubScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemSecuritySummary,
          name: AppRoutes.hubSystemSecuritySummary,
          builder: (context, state) => h92.SystemSecuritySummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemIdentity,
          name: AppRoutes.hubSystemIdentity,
          builder: (context, state) =>
              h87.SystemIdentityScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemClock,
          name: AppRoutes.hubSystemClock,
          builder: (context, state) =>
              h85.SystemClockScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemUsers,
          name: AppRoutes.hubSystemUsers,
          builder: (context, state) =>
              h95.SystemUsersScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSystemUserGroups,
          name: AppRoutes.hubSystemUserGroups,
          builder: (context, state) => h94.SystemUserGroupsScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubIpServices,
          name: AppRoutes.hubIpServices,
          builder: (context, state) =>
              h71.IpServicesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubCertificates,
          name: AppRoutes.hubCertificates,
          builder: (context, state) =>
              h70.CertificatesScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubNetworkToolsSummary,
          name: AppRoutes.hubNetworkToolsSummary,
          builder: (context, state) => h99.NetworkToolsSummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVpnHub,
          name: AppRoutes.hubVpnHub,
          builder: (context, state) =>
              h124.VpnHubScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubAdvancedPing,
          name: AppRoutes.hubAdvancedPing,
          builder: (context, state) =>
              h96.AdvancedPingScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubTracerouteAdvanced,
          name: AppRoutes.hubTracerouteAdvanced,
          builder: (context, state) => h102.TracerouteAdvancedScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubTorch,
          name: AppRoutes.hubTorch,
          builder: (context, state) =>
              h101.TorchScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubBandwidthTest,
          name: AppRoutes.hubBandwidthTest,
          builder: (context, state) =>
              h97.BandwidthTestScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubSniffer,
          name: AppRoutes.hubSniffer,
          builder: (context, state) =>
              h100.SnifferScreen(service: RouterSession.instance.service),
        ),
        GoRoute(
          path: AppRoutePaths.hubDeviceModeTools,
          name: AppRoutes.hubDeviceModeTools,
          builder: (context, state) => h98.DeviceModeToolsScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherProfileCatalog,
          name: AppRoutes.hubVoucherProfileCatalog,
          builder: (context, state) => h115.VoucherProfileCatalogScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubHotspotProfileSafety,
          name: AppRoutes.hubHotspotProfileSafety,
          builder: (context, state) => h6.HotspotProfileSafetyScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherTicketCatalog,
          name: AppRoutes.hubVoucherTicketCatalog,
          builder: (context, state) => h123.VoucherTicketCatalogScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherStatusCheck,
          name: AppRoutes.hubVoucherStatusCheck,
          builder: (context, state) => h122.VoucherStatusCheckScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherPortalReadiness,
          name: AppRoutes.hubVoucherPortalReadiness,
          builder: (context, state) =>
              const h113.VoucherPortalReadinessScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherSemanticsAudit,
          name: AppRoutes.hubVoucherSemanticsAudit,
          builder: (context, state) => h120.VoucherSemanticsAuditScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherProfileUsage,
          name: AppRoutes.hubVoucherProfileUsage,
          builder: (context, state) => h116.VoucherProfileUsageScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherDuplicateAudit,
          name: AppRoutes.hubVoucherDuplicateAudit,
          builder: (context, state) => h110.VoucherDuplicateAuditScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherBatchPreview,
          name: AppRoutes.hubVoucherBatchPreview,
          builder: (context, state) => h109.VoucherBatchPreviewScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherBatchCleanup,
          name: AppRoutes.hubVoucherBatchCleanup,
          builder: (context, state) => h108.VoucherBatchCleanupScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubHotspotStaleCookieCleanup,
          name: AppRoutes.hubHotspotStaleCookieCleanup,
          builder: (context, state) => h107.HotspotStaleCookieCleanupScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubHotspotExpirationIntegrity,
          name: AppRoutes.hubHotspotExpirationIntegrity,
          builder: (context, state) => h103.HotspotExpirationIntegrityScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubHotspotExpirationRepair,
          name: AppRoutes.hubHotspotExpirationRepair,
          builder: (context, state) => h104.HotspotExpirationRepairScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubHotspotProfileMonitorAudit,
          name: AppRoutes.hubHotspotProfileMonitorAudit,
          builder: (context, state) => h106.HotspotProfileMonitorAuditScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherPrintReadiness,
          name: AppRoutes.hubVoucherPrintReadiness,
          builder: (context, state) => const h114.VoucherPrintReadinessScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherHistoryIntegrity,
          name: AppRoutes.hubVoucherHistoryIntegrity,
          builder: (context, state) =>
              const h111.VoucherHistoryIntegrityScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherReprintFilter,
          name: AppRoutes.hubVoucherReprintFilter,
          builder: (context, state) => const h117.VoucherReprintFilterScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherSalesReconciliation,
          name: AppRoutes.hubVoucherSalesReconciliation,
          builder: (context, state) => h119.VoucherSalesReconciliationScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubHotspotLifecycleSummary,
          name: AppRoutes.hubHotspotLifecycleSummary,
          builder: (context, state) => h105.HotspotLifecycleSummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherSoftwareReadiness,
          name: AppRoutes.hubVoucherSoftwareReadiness,
          builder: (context, state) =>
              const h121.VoucherSoftwareReadinessScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherLifecycleConsistency,
          name: AppRoutes.hubVoucherLifecycleConsistency,
          builder: (context, state) => h112.VoucherLifecycleConsistencyScreen(
            service: RouterSession.instance.service,
          ),
        ),
        GoRoute(
          path: AppRoutePaths.hubVoucherSafetySummary,
          name: AppRoutes.hubVoucherSafetySummary,
          builder: (context, state) => h118.VoucherSafetySummaryScreen(
            service: RouterSession.instance.service,
          ),
        ),

        GoRoute(
          path: AppRoutePaths.voucherBatchLifecycleResult,
          name: AppRoutes.voucherBatchLifecycleResult,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! VoucherBatchLifecycleResultPayload) {
              return const _MissingPayloadScreen();
            }
            return VoucherBatchLifecycleResultScreen(
              title: payload.title,
              result: payload.result,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.voucherTicketDetail,
          name: AppRoutes.voucherTicketDetail,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! RequiredRowPayload) {
              return const _MissingPayloadScreen();
            }
            return HotspotTicketDetailScreen(
              service: RouterSession.instance.service,
              ticket: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.wireGuardPeerEdit,
          name: AppRoutes.wireGuardPeerEdit,
          builder: (context, state) {
            final payload = state.extra;
            if (payload is! WireGuardPeerEditPayload) {
              return const _MissingPayloadScreen();
            }
            return vpn_wg_peer.WireGuardPeerEditorScreen(
              service: RouterSession.instance.service,
              interfaceName: payload.interfaceName,
              row: payload.row,
            );
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportLive,
          name: AppRoutes.reportLive,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return LiveReportScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSales,
          name: AppRoutes.reportSales,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return RootMikroManagerSalesReportScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportUserLog,
          name: AppRoutes.reportUserLog,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return RootMikroManagerUserLogReportScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportMonthly,
          name: AppRoutes.reportMonthly,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return RootMikroManagerMonthlyResumeReportScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesProfile,
          name: AppRoutes.reportSalesProfile,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesProfileSummaryScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesIntegrity,
          name: AppRoutes.reportSalesIntegrity,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesIntegrityAuditScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesDuplicates,
          name: AppRoutes.reportSalesDuplicates,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesDuplicateAuditScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesDateRange,
          name: AppRoutes.reportSalesDateRange,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesDateRangeExportScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesLedger,
          name: AppRoutes.reportSalesLedger,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesLedgerScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesConsistency,
          name: AppRoutes.reportSalesConsistency,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesConsistencySummaryScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportExportHub,
          name: AppRoutes.reportExportHub,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return ReportExportHubScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesUniqueRevenue,
          name: AppRoutes.reportSalesUniqueRevenue,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesUniqueRevenueScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesRetention,
          name: AppRoutes.reportSalesRetention,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesRetentionAuditScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesDataQuality,
          name: AppRoutes.reportSalesDataQuality,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesDataQualityScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportManagementReadiness,
          name: AppRoutes.reportManagementReadiness,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return ManagementReadinessScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.reportManagerFreeze,
          name: AppRoutes.reportManagerFreeze,
          builder: (context, state) => const ManagerSoftwareFreezeScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.reportStaticAudit,
          name: AppRoutes.reportStaticAudit,
          builder: (context, state) => const ManagementStaticAuditNotesScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.reportValidationMatrix,
          name: AppRoutes.reportValidationMatrix,
          builder: (context, state) => const ManagementValidationMatrixScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.reportSalesCleanup,
          name: AppRoutes.reportSalesCleanup,
          builder: (context, state) {
            final service = RouterSession.instance.service;
            return SalesCleanupPreviewScreen(service: service);
          },
        ),
        GoRoute(
          path: AppRoutePaths.voucherHistory,
          name: AppRoutes.voucherHistory,
          builder: (context, state) => const VoucherHistoryScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Navigation')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Route introuvable : ${state.uri}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? extra,
  }) => context.pushNamed<T>(routeName, extra: extra);
}

Widget _requireRouter(String title, Widget Function() destination) {
  if (RouterSession.instance.connected) {
    return destination();
  }
  return _RouterConnectionRequiredScreen(title: title);
}

class _RouterConnectionRequiredScreen extends StatelessWidget {
  final String title;
  const _RouterConnectionRequiredScreen({required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.router_outlined, size: 48),
            const SizedBox(height: 16),
            const Text('Aucun routeur connecté.', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Ouvrez « Routeurs », sélectionnez un MikroTik puis '
              'connectez-vous avant d’ouvrir ce module.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.goNamed(AppRoutes.routers),
              icon: const Icon(Icons.router),
              label: const Text('Ouvrir les routeurs'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MissingPayloadScreen extends StatelessWidget {
  const _MissingPayloadScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Données de navigation absentes ou invalides.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
