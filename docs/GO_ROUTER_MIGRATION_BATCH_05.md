# go_router — lot de migration 05

## Fichiers migrés

29 fichiers supplémentaires de la partie réseau avancée ont été migrés :

- ARP ;
- Bridge / VLAN ;
- DHCP ;
- DNS ;
- IPv6 ;
- routage IP et policy routing ;
- VLAN interfaces ;
- VPN avancé ;
- Wi-Fi / CAPsMAN / provisioning / profils / ACL ;
- WireGuard peers ;
- Wireless ;
- ZeroTier.

## Résultat

Avant cette passe : 60 occurrences dans 60 fichiers.
Après cette passe : 31 occurrences dans 31 fichiers.

Le pont `PreparedAppRouter.pushPage<T>()` reste temporaire afin de préserver
les retours typés et de continuer la migration sans imposer immédiatement
toutes les routes finales nommées.

## Suite

Les derniers fichiers restants concernent surtout :
- Backup ;
- quelques écrans Hotspot ;
- Queues ;
- Routeurs / Settings ;
- System / Logging ;
- Tools ;
- quelques écrans Vouchers.

Objectif de la prochaine passe : approcher ou atteindre zéro
`MaterialPageRoute`.
