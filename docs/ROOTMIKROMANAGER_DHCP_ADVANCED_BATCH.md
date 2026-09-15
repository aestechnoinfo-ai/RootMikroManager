# DHCP avancé

Ce lot transforme DHCP d'un écran essentiellement consultatif en module de
gestion native.

Fonctions :
- serveurs DHCP : ajout, modification, activation/désactivation, suppression ;
- réseaux DHCP : gateway, DNS, domaine, NTP, WINS ;
- baux DHCP : statiques/dynamiques, création de réservation statique,
  conversion d'un bail dynamique en statique ;
- IP Pools partagés avec Hotspot sans dupliquer leur logique ;
- résumé global.

Les pools ne doivent pas inclure l'adresse IP du serveur/gateway DHCP.
La création complète d'un réseau reste volontairement explicite : pool,
network et serveur sont des objets RouterOS distincts.
