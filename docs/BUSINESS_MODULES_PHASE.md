# RootMikroManager — Business Modules Phase

Cette étape complète une grande partie des fonctions opérationnelles :

## Vouchers
- sélection d'un vrai profil Hotspot existant ;
- génération en lot ;
- historique SQLite ;
- séparation stricte entre profils et vouchers.

## PPP / PPPoE
- secrets ;
- profils ;
- connexions actives ;
- création d'un secret ;
- création d'un profil ;
- activation/désactivation/suppression.

## DHCP
- liste des leases ;
- ajout d'une lease statique ;
- suppression.

## DNS
- liste des entrées statiques ;
- ajout ;
- suppression.

## Queues
- Simple Queues ;
- ajout ;
- suppression.

## RouterOS
- helpers dédiés pour PPP, DHCP, DNS et Queues ;
- commandes CRUD centralisées ;
- architecture toujours indépendante de PHP/AWebServer.

L'APK n'est volontairement pas traité dans cette phase.
