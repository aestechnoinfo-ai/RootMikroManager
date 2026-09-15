# WinBox-like — Routage avancé, lot 04

## IPv4

- validation destination, gateway, distance, scope, target-scope et preferred source ;
- détection des routes par défaut dans `main` ;
- avertissement ECMP lorsque plusieurs gateways sont configurées ;
- contrôle `target-scope < scope` ;
- information sur les distances de backup ;
- inventaire enrichi : routes statiques/dynamiques, actives, HW offload, ECMP et tables.

## IPv6

- validation CIDR IPv6 ;
- validation gateway IPv6, y compris link-local avec `%interface` ;
- protection des routes dynamiques ;
- confirmation spécifique avant modification de `::/0`.

## Routing Tables

- protection de `main` ;
- validation du nom ;
- suppression bloquée lorsqu’une table est encore utilisée par :
  - une route IPv4 ;
  - une route IPv6 ;
  - une Routing Rule.

## Routing Rules

- validation IPv4/IPv6 source et destination ;
- détection des règles sans périmètre source/destination ;
- avertissements `lookup-only-in-table`, `drop` et `unreachable` ;
- confirmation explicite pour les politiques potentiellement dangereuses.

## VRF

VRF reste volontairement en lecture seule dans ce lot. L’inventaire est
amélioré avec recherche et affichage clair des interfaces. La modification
des VRF sera traitée séparément avec une protection de management plus
forte, car l’ordre des VRF et le déplacement d’interfaces peuvent modifier
les routes connectées.

## Tests ajoutés

- `test/routing_policy_analyzer_test.dart`
- `test/routing_input_validator_test.dart`

## Audit

- imports relatifs manquants : 0 ;
- collisions de routes : 0 ;
- `MaterialPageRoute` : 0 ;
- `pushPage()` : 0 ;
- `pushModule()` : 0 ;
- ancienne marque : 0 ;
- `FloatingActionButton` : 0 ;
- délimiteurs des fichiers modifiés : OK.

Flutter/Dart SDK n’est pas installé dans l’environnement d’exécution ;
aucun `flutter analyze`, test exécuté ou build APK n’est revendiqué.
