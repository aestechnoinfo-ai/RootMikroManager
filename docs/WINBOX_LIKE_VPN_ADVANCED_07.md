# WinBox-like — VPN avancé, lot 07

## WireGuard

Renforcements :

- validation nom, listen port et MTU ;
- validation stricte des clés publiques WireGuard ;
- validation des Allowed Addresses IPv4/IPv6 ;
- validation endpoint port et Persistent Keepalive ;
- avertissement lorsqu’un peer annonce `0.0.0.0/0` ou `::/0` ;
- confirmation avant suppression d’un peer ;
- confirmation renforcée avant suppression d’une interface contenant des peers ;
- aucune clé privée n’est demandée ou affichée.

## ZeroTier

- validation du Network ID sur 16 caractères hexadécimaux ;
- validation du nom d’interface ;
- avertissement `allow-default` ;
- avertissement `allow-global`.

## Back To Home

- correction du chemin RouterOS moderne vers
  `/ip/cloud/back-to-home-user` avec fallback de compatibilité ;
- maintien du masquage des clés privées, configurations client et QR ;
- vue de diagnostic prudente, sans manipulation agressive du service.

## Inventaire VPN

Le résumé inclut désormais séparément :

- WireGuard ;
- ZeroTier ;
- IPsec Active Peers ;
- L2TP clients ;
- SSTP clients ;
- OpenVPN clients ;
- Back To Home.

## Neighboring / découverte VPN

Correction importante :

- un peer WireGuard `/32` reste une cible `/32` ;
- `/31` et `/32` sont maintenant acceptés par le scanner IPv4 ;
- RootMikroManager ne transforme plus arbitrairement une IP peer en `/24` ;
- les Network IDs ZeroTier ne sont plus présentés comme des adresses IP ;
- les candidats VPN sont séparés des vrais Neighbors MNDP/CDP/LLDP.

Principe conservé :

MNDP/CDP/LLDP sont des mécanismes L2. Sur WireGuard, Back To Home et les
VPN routés, RootMikroManager utilise une découverte IP (API 8728/8729,
WinBox 8291 ou ports configurés), sans prétendre que le broadcast L2
traverse le tunnel.

## Tests ajoutés

- `test/vpn_input_validator_test.dart`
- `test/vpn_safety_analyzer_test.dart`

## Audit statique

- imports relatifs manquants : 0 ;
- collisions de routes : 0 ;
- `MaterialPageRoute` : 0 ;
- `pushPage()` : 0 ;
- `pushModule()` : 0 ;
- ancienne marque : 0 ;
- `FloatingActionButton` : 0 ;
- délimiteurs des fichiers modifiés : OK.

Le SDK Flutter/Dart n’est pas disponible dans cet environnement ; aucun
`flutter analyze`, test exécuté ou build APK n’est revendiqué.
