# RootMikroManager — Advanced Network Phase

## Traffic temps réel
- monitor-traffic RouterOS ;
- RX/TX bits/s ;
- RX/TX packets/s ;
- FastPath RX/TX ;
- TX queue drops ;
- rafraîchissement périodique.

## Neighbor Discovery
- lecture des voisins vus par le routeur ;
- IP ;
- MAC ;
- identity ;
- interface ;
- board ;
- version RouterOS ;
- protocole de découverte.

## RoMON
- statut RoMON ;
- activation/désactivation ;
- ports RoMON ;
- current-id.

## Sauvegardes
- JSON RootMikroManager dans le stockage applicatif ;
- backup binaire RouterOS ;
- export de configuration `.rsc`.

## Limite volontaire
Le module Neighbors ici interroge le routeur MikroTik connecté.
Un scan L2 directement depuis le téléphone (MNDP/LLDP au niveau natif)
nécessite une couche réseau Android/iOS dédiée et sera traité comme
module natif séparé.
