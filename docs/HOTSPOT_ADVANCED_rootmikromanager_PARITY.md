# Hotspot avancé - parité RootMikroManager

Référence principale : RootMikroManager v7.135 fourni dans `rootmikromanager.zip`.

## Active
- filtre par serveur ;
- User, Address, MAC, Uptime, Bytes In/Out, Time Left, Login By, Comment ;
- déconnexion avec confirmation ;
- comme `process/removeuseractive.php`, suppression du cookie du user avant
  suppression de la session active.

## Cookies
- User
- MAC Address
- Domain
- Expires In
- suppression individuelle.

## Hosts
- MAC Address
- Address
- To Address
- Server
- Comment
- suppression individuelle ;
- création rapide d'un IP Binding depuis un host.

## IP Binding
- Comment / Name
- MAC Address
- Address
- To Address
- Server
- Type : regular / bypassed / blocked
- enable / disable
- modification
- suppression avec nettoyage RootMikroManager :
  - Simple Queue nommée par MAC
  - Scheduler nommé par MAC
  - ARP portant l'adresse
  - DHCP Lease portant l'adresse

Le nettoyage est conditionnel : RootMikroManager ne tente de supprimer
que les éléments réellement trouvés.
