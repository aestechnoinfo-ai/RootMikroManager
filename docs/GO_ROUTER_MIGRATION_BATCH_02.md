# go_router — lot de migration 02

## Fichiers migrés

1. `lib/features/dashboard/dashboard_screen.dart`
2. `lib/features/hotspot/hotspot_management_screen.dart`
3. `lib/features/hotspot/hotspot_users_screen.dart`
4. `lib/features/vouchers/voucher_generator_screen.dart`
5. `lib/features/vouchers/voucher_operations_hub_screen.dart`
6. `lib/features/ppp/ppp_management_screen.dart`
7. `lib/features/ppp/ppp_hub_screen.dart`

## Stratégie

- Dashboard utilise désormais la vraie route nommée `module` et le pont
  `routes de domaine explicites`.
- Les écrans internes utilisent temporairement `PreparedAppRouter.pushPage<T>`.
- Ce pont est basé sur `go_router`, conserve les retours typés et permet une
  migration progressive sans déclarer des dizaines de routes finales d'un coup.
- Les écrans qui renvoient `bool` conservent leur contrat.

## Résultat

Baseline avant cette passe : 136 routes impératives dans 93 fichiers.
Après cette passe : 119 occurrences dans 86 fichiers.

17 occurrences ont donc été retirées de 7 fichiers métier.

## Prochaine passe

La prochaine cible prioritaire est la branche Reports :
- `reports_screen.dart` : 20 occurrences ;
- `report_export_hub_screen.dart` : 1 occurrence.

Ensuite :
- Hotspot avancé / actifs ;
- PPP actifs ;
- Monitoring ;
- System scripts/scheduler ;
- puis les modules réseau avancés.
