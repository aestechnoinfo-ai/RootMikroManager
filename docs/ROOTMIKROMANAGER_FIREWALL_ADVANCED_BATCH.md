# Firewall avancé

Ce lot remplace l'éditeur firewall générique par des formulaires spécialisés.

## Filter
Chain, action, protocole, connection-state, src/dst address, ports,
interfaces, commentaire et état.

## NAT
Chain, masquerade/src-nat/dst-nat/redirect/netmap, protocole,
src/dst address, dst port, interfaces, to-addresses et to-ports.

## Mangle
Packet mark, connection mark, routing mark, passthrough, protocole,
adresses, ports et interfaces.

## RAW
Actions accept/drop/notrack/jump/log/passthrough/return.

## Address Lists
Filtres Toutes/Statiques/Dynamiques, ajout, édition et suppression des
entrées statiques. Les entrées dynamiques restent en lecture seule.

## Compteurs
Les listes affichent bytes/packets et proposent reset counters lorsqu'il
est exposé par RouterOS.
