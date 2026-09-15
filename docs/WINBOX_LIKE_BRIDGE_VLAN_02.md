# WinBox-like — Bridge + VLAN, lot 02

## Périmètre

Ce lot durcit la gestion native RouterOS de niveau 2 :

- Bridges ;
- Bridge Ports ;
- Bridge VLAN Table ;
- VLAN Filtering ;
- interfaces VLAN ;
- audit du chemin de management ;
- compatibilité RouterOS / HW offload.

## VLAN Filtering sécurisé

L’activation de `vlan-filtering` n’est plus effectuée dans l’éditeur général du bridge.
Elle passe par `BridgeVlanActivationScreen` qui charge :

- ports du bridge ;
- Bridge VLAN Table ;
- interfaces VLAN ;
- adresses IP ;
- état actuel du bridge.

Avant activation, l’écran analyse notamment :

- absence de Bridge VLAN Table ;
- absence du port CPU/bridge dans les VLANs ;
- ports access avec PVID incohérent ;
- trunks sans `ingress-filtering` ;
- port présent à la fois tagged et untagged ;
- plusieurs VLAN IDs dans une entrée comportant des ports untagged ;
- absence apparente d’adresse IP de management sur le bridge ou ses interfaces VLAN.

Les risques critiques bloquent l’activation et l’utilisateur doit taper exactement le nom du bridge pour confirmer une activation autorisée.

## Bridge Ports

- recherche ;
- compteur HW offload ;
- filtre HW ;
- enable/disable ;
- retrait avec confirmation ;
- validation PVID ;
- validation horizon/path-cost/internal-path-cost ;
- avertissement trunk sans ingress filtering ;
- avertissement BPDU Guard hors port access.

## Bridge VLAN Table

- recherche ;
- affichage/masquage des entrées dynamiques ;
- affichage `current-tagged` / `current-untagged` ;
- détection visuelle de la présence CPU/bridge ;
- protection supplémentaire lors de la suppression d’un VLAN pouvant porter le management ;
- validation des VLAN IDs simples, plages et listes.

À partir de RouterOS 7.17, les Interface Lists sont proposées directement comme valeurs tagged/untagged. Les noms de listes ne sont pas transformés par un préfixe interne.

## Interfaces VLAN

- recherche ;
- validation VLAN ID et MTU ;
- avertissement spécifique pour `use-service-tag` ;
- suppression avec confirmation ;
- rappel du comportement dynamique du Bridge VLAN Table lorsqu’une interface VLAN est créée sur un bridge filtré.

## Bridges

- ajout/modification via un éditeur dédié ;
- suppression bloquée tant que des ports ou entrées VLAN dépendent du bridge ;
- VLAN Filtering toujours séparé du formulaire courant ;
- validation nom et MTU.

## Contrôles statiques

- 19 fichiers ajoutés/modifiés ;
- imports relatifs manquants : 0 ;
- collisions de routes : 0 ;
- `MaterialPageRoute` : 0 ;
- `pushPage()` / `pushModule()` : 0 ;
- ancien sous-dossier préparatoire de navigation : 0 ;
- ancienne marque : 0 ;
- `FloatingActionButton` : 0 ;
- délimiteurs des fichiers modifiés : OK.

Le SDK Flutter/Dart n’est pas disponible dans l’environnement d’exécution de cette passe ; aucun `flutter analyze`, test Flutter ou build APK n’est donc revendiqué.
