# go_router — routes nommées finales, lot 06

## Périmètre

Cette passe migre 16 fichiers supplémentaires :

- Firewall Management ;
- Firewall Rules spécialisés ;
- Interfaces Management ;
- Wi-Fi Access List ;
- Wi-Fi Profiles ;
- WireGuard Peers (branche Network) ;
- Wireless Inventory ;
- Queue Tree ;
- Queue Types ;
- Simple Queues ;
- Logging Actions ;
- Logging Buffers ;
- Logging Rules ;
- Logs Management ;
- Settings / éditeur de voucher ;
- connexion à un routeur enregistré.

## Payloads spécialisés

De nouveaux payloads typés couvrent :

- règles Firewall génériques ;
- règles Firewall avancées ;
- backend Wi-Fi moderne/legacy ;
- type de profil Wi-Fi ;
- routeur enregistré.

Les données sensibles restent en mémoire dans `GoRouterState.extra`.

## Progression

- `MaterialPageRoute` : 0
- `pushPage()` avant : 41
- `pushPage()` après : 25
- `pushNamed()` actifs : 110
- nouvelles routes : 15

Le pont temporaire est maintenant suffisamment réduit pour préparer sa
suppression complète dans les prochaines passes.
