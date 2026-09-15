# go_router — routes nommées finales, lot 04

## Périmètre

Cette passe migre 15 écrans supplémentaires :

- Discovery hub ;
- scan IP ;
- inventaire Neighbors ;
- découverte RoMON ;
- découverte VPN ;
- Backup hub ;
- Backup legacy ;
- Hotspot expiration/cookies ;
- gestion profils Hotspot ;
- Hotspot Server Profiles ;
- Hotspot Servers ;
- configuration Hotspot ;
- impression depuis l'éditeur utilisateur ;
- IP Pools ;
- ARP.

## Discovery / VPN

La sauvegarde d'un routeur détecté utilise désormais
`DiscoveryCandidatePayload` via `GoRouterState.extra`.

Cela permet de conserver les informations de découverte en mémoire sans
placer les données RouterOS dans l'URL. Les sources restent distinctes :
Neighbors L2, RoMON, scan IP et réseaux VPN (WireGuard, BackToHome,
ZeroTier ou CIDR manuel).

## Hotspot

La navigation d'expiration conserve la règle fonctionnelle :
cookie Hotspot → session active → ticket/scheduler selon le flux concerné.
Ce lot modifie uniquement la navigation et ne change pas cette séquence.

## Progression

- `MaterialPageRoute` : 0
- `pushPage()` avant : 75
- `pushPage()` après : 60
- appels `pushNamed()` actifs : 75
- nouvelles routes de cette passe : 25
