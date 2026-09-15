# go_router — lot de migration 04

## Fichiers migrés

18 fichiers supplémentaires ont été sortis de `MaterialPageRoute` :

- Firewall / Mangle : outils, hubs, règles, gestion, anti-partage ;
- Queues : monitoring ;
- VPN : interfaces WireGuard ;
- Réseau : routes IP, listes d'interfaces, détail interface, hub et gestion ;
- Discovery : voisinage, RoMON, VPN discovery et scan IP.

Le pont `PreparedAppRouter.pushPage<T>()` reste volontairement utilisé
pendant cette phase pour conserver les retours typés et éviter un big-bang
des routes finales.

## Suite recommandée

Poursuivre avec :
- DHCP / DNS ;
- Bridge / VLAN ;
- IPv6 / routing policy ;
- Wi-Fi ;
- VPN avancé et peers WireGuard ;
- Backup / Tools / Settings ;
- derniers écrans Hotspot restants.

Une fois les routes impératives à zéro, remplacer progressivement le pont
temporaire par des routes nommées finales par domaine.
