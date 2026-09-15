# WinBox-like — WiFi / Wireless / CAPsMAN, lot 06

## Séparation des piles

RootMikroManager maintient une séparation explicite entre :

- `/interface/wifi` : pile WiFi moderne ;
- `/interface/wireless` : pile Wireless legacy.

Les profils de sécurité, Registration Tables et capacités CAPsMAN ne sont
pas fusionnés artificiellement.

## WiFi moderne

Renforcement des profils :

- Configuration ;
- Channel ;
- Security ;
- Datapath.

Validations ajoutées :

- nom ;
- VLAN 1–4094 ;
- fréquence ;
- passphrase WPA-PSK ;
- Authentication Types.

Les secrets restent en écriture uniquement : l’application ne tente pas
d’afficher une passphrase existante.

## Access Lists

- validation MAC ;
- Signal Range ;
- VLAN ;
- avertissement sur les règles `reject` trop générales ;
- avertissement `query-radius` ;
- confirmation avant suppression ;
- rappel explicite que l’ordre des règles est significatif.

## Provisioning

- validation Radio MAC ;
- Master Configuration exigée pour les actions `create-*` ;
- détection des règles trop générales ;
- rappel que le provisioning est évalué dans l’ordre.

## CAPsMAN

L’écran indique maintenant séparément le nombre d’interfaces :

- WiFi modernes ;
- Wireless legacy.

Les Remote CAP et règles de provisioning restent rattachés à la pile WiFi
moderne.

## Registration Table

La déconnexion d’un client exige une confirmation. RootMikroManager rappelle
que le client peut immédiatement se reconnecter si la configuration Wi‑Fi
l’autorise.

## Scan

Le scan :

- gère proprement l’absence d’interface compatible ;
- rappelle qu’un scan peut perturber temporairement une radio utilisée en
  production ;
- conserve le backend exact de l’interface sélectionnée.

## Security inventory

Les profils modernes et legacy peuvent être consultés dans un même
inventaire, mais leur backend reste visible. Les champs assimilables à des
mots de passe, passphrases ou pre-shared keys ne sont pas affichés.

## Tests

- `test/wifi_wireless_validator_test.dart`
- `test/wifi_wireless_safety_analyzer_test.dart`

## Audit statique

- imports relatifs manquants : 0 ;
- collisions de routes : 0 ;
- `MaterialPageRoute` : 0 ;
- `pushPage()` : 0 ;
- `pushModule()` : 0 ;
- ancienne marque : 0 ;
- `FloatingActionButton` : 0 ;
- délimiteurs des fichiers modifiés : OK.

Le SDK Flutter/Dart n’est pas disponible dans l’environnement d’exécution.
Aucun `flutter analyze`, test exécuté ou build APK n’est revendiqué.
