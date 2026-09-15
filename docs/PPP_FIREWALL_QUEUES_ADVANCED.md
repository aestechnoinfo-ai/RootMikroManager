# RootMikroManager — PPP, Firewall & Queues Advanced

## PPP / PPPoE
- Secrets : ajout, modification, activation, désactivation, suppression.
- Profiles : ajout, modification, activation/désactivation lorsque supporté.
- Active : consultation et déconnexion de session.

## Firewall
Le module devient un hub :
- Filter Rules ;
- NAT ;
- Mangle ;
- Address Lists.

Les primitives RouterOS Mangle et Address Lists sont maintenant intégrées.

## Queues
Le module devient un hub :
- Simple Queues ;
- Queue Tree.

Queue Tree prend en charge :
- name ;
- parent ;
- packet-mark ;
- limit-at ;
- max-limit ;
- priority ;
- edit ;
- enable/disable ;
- delete.

## Toujours sans FloatingActionButton
Les créations restent accessibles par boutons standards dans le contenu.
