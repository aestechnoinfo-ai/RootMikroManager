# WinBox-like — Interfaces + IPv4 + ARP + Routes, lot 01

## Périmètre

Ce lot durcit la base d’administration réseau native : interfaces RouterOS,
détail et monitoring d’interface, Interface Lists, adresses IPv4, ARP,
routes IPv4 et résumé routage/IP.

## Interfaces

- compteurs running / désactivées / dynamiques ;
- enable/disable masqué pour les interfaces dynamiques ;
- édition directe bloquée sur les interfaces dynamiques ;
- validation du nom et du MTU ;
- détail enrichi par `/interface/ethernet/monitor` quand disponible ;
- monitoring RX/TX ouvert directement sur l’interface sélectionnée.

## Interface Lists

La vue rappelle l’ordre RouterOS : include → exclude → membres statiques.
Un bridge ajouté à une liste n’équivaut pas automatiquement à tous ses ports,
point important pour le Neighbor Discovery.

## IPv4

Ajout de `IpAddressEditorScreen` : création/modification, validation CIDR,
Network facultatif, sélection d’interface, lecture seule des adresses dynamiques
et confirmation avant suppression d’une adresse statique.

## ARP

Validation IPv4/MAC, compteurs statique/dynamique/failed, confirmation avant
suppression et protection des entrées dynamiques.

## Routes IPv4

Validation destination/gateway, y compris syntaxe RouterOS `%interface`,
`@routing-table` et ECMP séparé par virgules ; validation distance/scope/
target-scope ; filtres actif/inactif/désactivé ; confirmation avant suppression ;
détail enrichi avec Active, Dynamic, Disabled et HW offload.

## Contrôles statiques

- 18 fichiers ajoutés ou modifiés ;
- imports relatifs manquants : 0 ;
- collisions de routes : 0 ;
- `MaterialPageRoute` : 0 ;
- `pushPage()` : 0 ;
- `pushModule()` : 0 ;
- ancien sous-dossier de navigation : 0 ;
- ancienne marque : 0 ;
- `FloatingActionButton` : 0.

Flutter/Dart SDK n’étant pas installé dans l’environnement d’exécution,
aucun `flutter analyze` ou build APK n’est revendiqué à ce stade.
