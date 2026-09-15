# Outils réseau avancés

Ce lot ajoute :
- Ping avancé ;
- Traceroute ;
- Torch ;
- Bandwidth Test TCP/UDP ;
- Packet Sniffer ;
- lecture du Device Mode ;
- résumé de disponibilité ;
- hub Outils réseau.

## Sécurité et charge
Le Bandwidth Test peut consommer beaucoup de CPU et toute la bande passante.
RootMikroManager demande donc une limite TX/RX et propose 10M par défaut.

Le Device Mode est affiché en lecture seule. RootMikroManager ne tente pas
d'activer automatiquement les fonctions protégées, car certaines modifications
de Device Mode exigent une confirmation physique sur le routeur.

## Sniffer
La capture est stockée dans un fichier du routeur. Le gestionnaire de fichiers
déjà présent dans l'application peut ensuite servir à retrouver la capture.

## Permissions RouterOS
Ping, traceroute et bandwidth-test dépendent notamment de la policy `test`.
Torch et Sniffer dépendent de la policy `sniff`.
