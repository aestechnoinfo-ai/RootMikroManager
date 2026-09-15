# Routage & IP avancé

Ce lot ajoute :
- routes IPv4 `/ip/route` ;
- état détaillé via `/routing/route` ;
- tables de routage ;
- ARP statique/dynamique ;
- proxy ARP individuel via `published` ;
- adresses IP ;
- IP Neighbors ;
- résumé routage.

## Séparation lecture/écriture
`/routing/route` est utilisé pour l'observation détaillée.
Les créations, modifications et suppressions IPv4 passent par `/ip/route`.

## Routes
L'éditeur prend en charge destination, gateway, routing-table, distance,
scope, target-scope, check-gateway, preferred source, HW offload, commentaire
et état.

## ARP
Les entrées dynamiques sont affichées sans édition. Les entrées statiques
peuvent définir IP, MAC, interface, commentaire et `published`.
