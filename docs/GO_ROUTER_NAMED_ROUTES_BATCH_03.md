# go_router — routes nommées finales, lot 03

## Domaines migrés

Cette passe supprime le pont générique dans neuf écrans à forte concentration :

- Monitoring ;
- Scheduler ;
- Scripts ;
- Firewall Mangle / partage Internet ;
- Queue Monitor ;
- WireGuard Interfaces ;
- Routes IPv4 ;
- Interface Lists ;
- Interface Detail.

## Routes nommées ajoutées

18 routes finales supplémentaires couvrent le monitoring, les éditeurs/détails
System, Mangle, Queues, WireGuard, routes IPv4 et interfaces.

Les lignes RouterOS nécessaires aux écrans d'édition ou de détail transitent
par `GoRouterState.extra` via des payloads typés. Elles ne sont pas sérialisées
dans l'URL.

## Progression

- `MaterialPageRoute` : 0
- `pushPage()` avant : 94
- `pushPage()` après : 75
- appels `pushNamed()` actifs : 60

Le dossier `core/navigation` reste encore conservé pendant la
migration. Son renommage en `core/navigation` sera effectué lorsque le pont
`pushPage()` sera suffisamment réduit, afin d'éviter une modification massive
d'imports pendant la même passe fonctionnelle.
