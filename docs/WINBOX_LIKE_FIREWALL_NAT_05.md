# WinBox-like — Firewall + NAT avancé, lot 05

## Périmètre

Ce lot renforce la gestion native RouterOS pour :

- Filter Rules ;
- NAT ;
- Mangle ;
- RAW ;
- Address Lists ;
- statistiques firewall ;
- ordre, duplication et compteurs.

## Ordre des règles

RouterOS traite les règles de chaque chaîne de haut en bas.

Les écrans avancés permettent maintenant :

- monter une règle ;
- descendre une règle ;
- dupliquer une règle ;
- reset des compteurs ;
- enable/disable ;
- suppression confirmée.

Une duplication est volontairement créée `disabled=yes` pour éviter qu’une
copie devienne immédiatement active avant vérification.

Les entrées dynamiques et dummy sont protégées contre édition, déplacement,
duplication et suppression directe.

## Filter

Validation :

- chain ;
- IPv4/CIDR source/destination ;
- ports et plages de ports ;
- connection-state.

Analyse de sécurité :

- drop/reject trop large dans `input` ;
- accept trop large dans `input` ;
- ports sans protocole compatible ;
- FastTrack hors `forward` ;
- FastTrack sans `established,related` ;
- rappel des fonctions contournées par FastTrack.

## NAT

Validation :

- chaîne ;
- IPv4/CIDR et plages IPv4 ;
- ports ;
- `to-addresses` ;
- `to-ports`.

Analyse :

- cohérence `srcnat` / `dstnat` ;
- destination obligatoire pour `dst-nat` ;
- ports NAT limités aux protocoles compatibles.

## Mangle

- New Mark obligatoire pour les actions `mark-*` ;
- contrôle des adresses et ports ;
- avertissement spécifique `mark-routing` dans `input`.

FastTrack et Policy Routing doivent rester coordonnés : le trafic FastTrack
utilise le chemin rapide et peut ignorer les traitements associés aux
routing marks / VRF.

## RAW

Les règles `drop` ou `notrack` sans source, destination ni interface
déclenchent une confirmation explicite, car RAW intervient avant Connection
Tracking.

## Address Lists

- validation nom de liste ;
- IPv4, CIDR et plages IPv4 ;
- timeout ;
- protection des entrées dynamiques ;
- confirmation de suppression avec rappel des dépendances firewall.

## Tests

- `test/firewall_input_validator_test.dart`
- `test/firewall_safety_analyzer_test.dart`

## Audit statique

- imports relatifs manquants : 0 ;
- collisions de routes : 0 ;
- `MaterialPageRoute` : 0 ;
- `pushPage()` : 0 ;
- `pushModule()` : 0 ;
- ancienne marque : 0 ;
- `FloatingActionButton` : 0 ;
- délimiteurs des fichiers modifiés : OK.

Flutter/Dart SDK n’est pas disponible dans l’environnement d’exécution ;
aucun `flutter analyze`, test exécuté ou build APK n’est revendiqué.
