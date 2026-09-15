# go_router — routes nommées finales, lot 05

## Périmètre

Cette passe migre 19 fichiers supplémentaires vers des routes nommées réelles :

- Internet Sharing ;
- Bridge Ports ;
- Bridge VLAN Table ;
- DHCP Leases ;
- DHCP Networks ;
- DHCP Servers ;
- DNS Static ;
- IPv6 Addresses ;
- IPv6 Routes ;
- Routing Rules ;
- Routing Tables ;
- VLAN ;
- Wi-Fi Provisioning ;
- ZeroTier Interfaces ;
- Bridge/VLAN Hub ;
- DHCP Hub ;
- DNS Hub ;
- Routing/IP Hub ;
- VPN Hub.

## Routes ajoutées

39 routes stables couvrent les éditeurs et les destinations de hubs de ce lot.

Les lignes RouterOS nécessaires aux écrans d’édition restent transportées via
`GoRouterState.extra` avec `OptionalRowPayload` ou `RequiredRowPayload`.
Aucun mot de passe, secret WireGuard, secret Wi-Fi ou identifiant sensible
n’est placé dans les URLs.

## Progression

- `MaterialPageRoute` : 0
- `pushPage()` avant : 60
- `pushPage()` après : 41
- `pushNamed()` actifs : 94
- collisions de noms de routes : 0
- collisions de chemins : 0

Les cas Firewall générique et profils Wi-Fi complexes restent temporairement
sur le pont `pushPage()` afin de leur donner des payloads spécialisés dans le
lot suivant au lieu d’introduire une route fragile.
