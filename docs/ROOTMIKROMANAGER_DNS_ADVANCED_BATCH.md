# DNS avancé

Ce lot transforme DNS en module natif complet :
- configuration globale ;
- DNS statique ;
- cache DNS ;
- purge du cache ;
- DNS over HTTPS ;
- Adlist lorsque la version RouterOS le supporte ;
- diagnostic de résolution depuis le routeur ;
- résumé DNS.

## Sécurité
`allow-remote-requests=yes` permet aux clients d'utiliser le routeur comme
serveur/cache DNS. Cette option doit être protégée par des règles Firewall afin
de ne pas exposer un résolveur DNS ouvert sur Internet.

## Cache
RootMikroManager utilise `/ip/dns/cache/all` lorsque disponible, avec repli sur
`/ip/dns/cache`, puis `/ip/dns/cache/flush` pour la purge.

## DNS statique
L'éditeur distingue explicitement les entrées DNS des profils Hotspot et des
vouchers. Il supporte notamment A, AAAA, CNAME, FWD et NXDOMAIN selon les
capacités de la version RouterOS.
