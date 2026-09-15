# go_router — lot de migration 03

## Fichiers migrés dans cette passe

1. `lib/features/reports/reports_screen.dart`
2. `lib/features/reports/report_export_hub_screen.dart`
3. `lib/features/hotspot/hotspot_advanced_screen.dart`
4. `lib/features/hotspot/hotspot_active_screen.dart`
5. `lib/features/ppp/ppp_active_screen.dart`
6. `lib/features/monitoring/monitoring_hub_screen.dart`
7. `lib/features/system/scheduler_management_screen.dart`
8. `lib/features/system/scripts_management_screen.dart`

## Résultat

- `reports_screen.dart` : 20 routes impératives supprimées.
- `report_export_hub_screen.dart` : 1 supprimée.
- Hotspot avancé/actifs : 5 supprimées.
- PPP actifs : 2 supprimées.
- Monitoring : 3 supprimées.
- Scheduler + Scripts : 4 supprimées.

Cette passe retire 35 occurrences supplémentaires.

Le pont `PreparedAppRouter.pushPage<T>()` reste temporaire pour les écrans
qui n'ont pas encore une route finale dédiée. Les retours typés sont préservés.

## Étape suivante

Continuer avec :
- firewall / mangle ;
- queues ;
- VPN / WireGuard ;
- routes IP ;
- interfaces ;
- DHCP / DNS ;
- découverte ;
- backup / outils ;
puis remplacer progressivement le pont temporaire par de vraies routes nommées.
